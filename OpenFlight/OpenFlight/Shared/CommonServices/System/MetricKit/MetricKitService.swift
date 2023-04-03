//    Copyright (C) 2023 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation
import GroundSdk
import MetricKit
import Combine
import SwiftyUserDefaults

// MARK: - Private Objects
/// The different log types.
private enum LogType: CaseIterable {
    /// Log containing `MXMetricPayload` body.
    case metric
    /// Log containing `MXDiagnosticPayload` body.
    case diagnostic

    /// The log file extension.
    var fileExtension: String {
        switch self {
        case .metric:  return "metric"
        case .diagnostic:  return "diagnostic"
        }
    }

    /// The log filename prefix.
    var prefix: String {
        switch self {
        case .metric:  return "Metric_"
        case .diagnostic:  return "Diagnostic_"
        }
    }

    /// The metric log files supported extensions.
    static var supportedExtensions: [String] {
        allCases.map { $0.fileExtension }
    }
}

/// The `Log` structure dedicated to handle Metric logs.
private struct Log {
    let type: LogType
    let url: URL
    let jsonBody: [String: Any]
}

// MARK: - Private Extensions
/// The tag used for `ULog`.
private extension ULogTag {
    static let tag = ULogTag(name: "MetricKitService")
}

/// `URL` extension.
private extension URL {
    /// The `LogType` corresponding to the current `URL`.
    var logType: LogType? {
        switch self.pathExtension {
        case LogType.metric.fileExtension:
            return .metric
        case LogType.diagnostic.fileExtension:
            return .diagnostic
        default:
            return nil
        }
    }

    /// The `URL` file content body's  json dictionary.
    var jsonBody: [String: Any] {
        guard let data = try? Data(contentsOf: self) else { return .empty }
        return (try? data.jsonObject) ?? .empty
    }

    /// The `Log` corresponding to the current `URL`.
    var log: Log? {
        guard let logType = self.logType else { return nil }
        return Log(type: logType,
                   url: self,
                   jsonBody: self.jsonBody)
    }
}

// MARK: - Service Protocol
/// The protocol defining the metric kit service.
public protocol MetricKitService: AnyObject {

    /// Starts metric logging.
    func startLogging()

    /// Stops metric logging.
    /// - WARNING:
    ///   This method calls `MXMetricManager.shared.remove(_)`.
    ///   Calling it from a method that deallocates the object might cause app crashing.
    func stopLogging()

    /// Clears all logs stored in the device.
    func clearLogs()

    /// Deletes specified logs from their urls.
    func deleteLogs(at urls: [URL])

    /// The urls list of stored metric logs.
    var logUrls: [URL] { get }

    /// The log urls publisher.
    var logUrlsPublisher: Published<[URL]>.Publisher { get }

    /// Returns a list of log urls created at a specific date.
    ///
    ///  - Parameter date: the log creation date
    ///  - Returns: the list of stored logs urls
    func urls(for date: Date) -> [URL]

    /// Returns a new metric signpost.
    ///
    ///  - Parameter category: the log category
    ///  - Returns: the `MetricKitLogger`
    func newLog(category: String) -> MetricKitLogger
}

// MARK: - Service Implementation
/// An implementation of the `MetricKitService` protocol.
public class MetricKitServiceImpl: NSObject {
    /// The current log urls.
    @Published private var currentLogUrls = [URL]()
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// Prohibits the use of constructor without parameter.
    @available(*, unavailable)
    override public init() {}

    /// Constructor.
    ///
    /// - Parameter autoStart: whether the logging must be started automatically
    init(autoStart: Bool = false) {
        super.init()
        ULog.i(.tag, "Init - autoStart: \(autoStart)")
        createLogDirectoryIfNeeded()
        updateCurrentLogUrls()
        if autoStart { startLogging() }
    }
}

// MARK: Listeners
private extension MetricKitServiceImpl {
    /// Listens the App state changes to stop logging when app will terminate.
    func listenAppState() {
        ULog.i(.tag, "Listening App states")
        UIApplication.statePublisher
            .filter { $0 == .willTerminate }
            .sink { [unowned self] _ in
                ULog.i(.tag, "App will terminate")
                // TODO: Ensure this couldn't cause crashes.
                stopLogging()
            }
            .store(in: &cancellables)
    }
}

// MARK: Log files
private extension MetricKitServiceImpl {

    /// The `DateFormatter` used to generate filenames.
    var dateFormatter: DateFormatter {
        DateFormatter.customFormat("yyyy-MM-dd-HHmmss")
    }

    /// The logs folder name.
    static let logsFolderName = "MetricLogs"

    /// The  logs base url.
    var logsUrl: URL? {
        FileManager.default.urls(for: .documentDirectory,
                                 in: .userDomainMask)
        .first?
        .appendingPathComponent(Self.logsFolderName)
    }

    /// Creates the logs directory if needed.
    func createLogDirectoryIfNeeded() {
        guard let logsUrl = logsUrl,
              !FileManager.default.fileExists(atPath: logsUrl.path)
        else { return }
        ULog.i(.tag, "Creating metric log directory")
        try? FileManager.default.createDirectory(at: logsUrl, withIntermediateDirectories: true)
    }

    /// Returns the log file name.
    ///
    /// - Parameter logType: the type of log
    /// - Returns: the file name for the current date
    func filename(for logType: LogType) -> String {
        logType.prefix
        + "\(dateFormatter.string(from: Date()))"
        + "." + logType.fileExtension
    }

    /// Returns the `LogType`'s `URL` for a new log.
    ///
    /// - Parameter logType: the type of log
    /// - Returns: the log file url
    func newLogUrl(for logType: LogType) -> URL? {
        logsUrl?.appendingPathComponent(filename(for: logType))
    }

    /// All logs stored in the device.
    var allLogs: [Log] {
        guard let logsUrl = logsUrl else { return [] }
        guard let urls = try? FileManager.default.contentsOfDirectory(at: logsUrl,
                                                                      includingPropertiesForKeys: nil)
        else { return [] }
        return urls
        // Filter only metric files.
            .filter { LogType.supportedExtensions.contains($0.pathExtension) }
            .compactMap { $0.log }
        // Sort them by creation date.
            .sorted { creationDate(of: $0) ?? .distantPast > creationDate(of: $1) ?? .distantPast }
    }

    /// Returns the log creation date.
    ///
    /// - Parameter log: the log
    /// - Returns: the creation date if exists
    func creationDate(of log: Log) -> Date? {
        let filename = log.url.lastPathComponent
        // Escaping prefix and fileExtension allows handling special regex chars in the strings.
        let prefix = NSRegularExpression.escapedPattern(for: log.type.prefix)
        let fileExtension = NSRegularExpression.escapedPattern(for: log.type.fileExtension)
        // Create a regex to extract the date string.
        let regex = #"^\#(prefix)(.*)\.\#(fileExtension)$"#
        // 1 - Check if the string match a metric log filename pattern.
        // 2 - Get the last match (should have just one).
        // 3 - Get the catched group '(.*)' representing the date.
        if let result = try? filename.search(regexPattern: regex),
           let match = result.matches.last,
           let dateString = match.groups.first {
            return dateFormatter.date(from: dateString)
        }
        return nil
    }

    /// Updates the current log urls published property.
    func updateCurrentLogUrls() {
        Task { @MainActor in
            currentLogUrls = allLogs.map(\.url)
        }
    }
}

// MARK: MetricKitService protocol
extension MetricKitServiceImpl: MetricKitService {
    public func startLogging() {
        ULog.i(.tag, "Start logging Metrics")
        MXMetricManager.shared.add(self)
        listenAppState()
    }

    public func stopLogging() {
        ULog.i(.tag, "Stop logging Metrics")
        MXMetricManager.shared.remove(self)
        cancellables = []
    }

    // TODO: Clean old logs depending some rules to fix.
    public func clearLogs() {
        ULog.i(.tag, "Deleting all stored metric logs")
        for log in allLogs {
            try? FileManager.default.removeItem(at: log.url)
        }
        updateCurrentLogUrls()
    }

    public func deleteLogs(at urls: [URL]) {
        allLogs.map(\.url)
            .filter { urls.contains($0) }
            .forEach { try? FileManager.default.removeItem(at: $0) }
        updateCurrentLogUrls()
    }

    public var logUrls: [URL] { currentLogUrls }

    public var logUrlsPublisher: Published<[URL]>.Publisher {
        $currentLogUrls
    }

    public func urls(for date: Date) -> [URL] {
        allLogs.filter {
            // Filter only logs created at specified date.
            creationDate(of: $0)?.isSameDay(date: date) ?? false
        }
        .map(\.url)
    }

    public func newLog(category: String) -> MetricKitLogger {
        MetricKitLogger(category: category)
    }
}

// MARK: MXMetricManagerSubscriber
extension MetricKitServiceImpl: MXMetricManagerSubscriber {
    // TODO: Add relevant SignPost in the app.

    /// This method is invoked when a new MXMetricPayload has been received.
    /// You can expect for this method to be invoked atleast once per day when the app is running and subscribers are available.
    /// If no subscribers are available, this method will not be invoked.
    /// Atleast one subscriber must be available to receive metrics.
    /// This method is invoked on a background queue.
    public func didReceive(_ payloads: [MXMetricPayload]) {
        ULog.i(.tag, "didReceive metric payloads (count: \(payloads.count)): \(payloads)")
        // Get the first playload and save it on the device.
        guard let firstPayload = payloads.first else { return }
        if let url = newLogUrl(for: .metric) {
            try? firstPayload.jsonRepresentation().write(to: url)
            updateCurrentLogUrls()
        }
    }

    /// This method is invoked when a new MXDiagnosticPayload has been received.
    /// You can expect for this method to be invoked atleast once per day when the app is running and subscribers are available.
    /// If no subscribers are available, this method will not be invoked.
    /// Atleast one subscriber must be available to receive diagnostics.
    /// This method is invoked on a background queue.
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        ULog.i(.tag, "didReceive diagnostic payloads (count: \(payloads.count)): \(payloads)")
        // Get the first playload and save it on the device.
        guard let firstPayload = payloads.first else { return }
        if let url = newLogUrl(for: .diagnostic) {
            try? firstPayload.jsonRepresentation().write(to: url)
            updateCurrentLogUrls()
        }
    }
}
