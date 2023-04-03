//    Copyright (C) 2020 Parrot Drones SAS
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

import SwiftyUserDefaults
import GroundSdk

/// Class to manage debug logs.
public class ParrotDebug {
    // MARK: - Public Properties
    public static var currentLogDirectory: URL?

    // MARK: - Private Properties
    private static let debugTag = ULogTag(name: "ParrotDebug")
    private static let maxSizeLogMb = 2 * 1024 // 2 GB
    private static var activeLogBinRecorder: RotatingLogRecorder?
    private static let streamDbgPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        as NSString).appendingPathComponent("stream")
}

// MARK: - Public Funcs
public extension ParrotDebug {

    private static func cleanOldLogs() {
        // TODO: Add metric logs cleaning
        try? FileManager.reduceDirectorySize(url: logsURL, fileExt: nil, totalMaxSizeMb: maxSizeLogMb, includingSubfolders: true)
    }

    /// Start smart log.
    static func smartStartLog() {
        cleanOldLogs()
        if !Defaults.hasKey(\.activatedLog) {
            // Use the default configuration.
            #if DEBUG
            startLog()
            #else
            if Bundle.main.isInHouseBuild {
                startLog()
            }
            #endif
        } else {
            if Defaults.activatedLog == true {
                startLog()
            }
        }
    }

    /// Starts Log.
    static func startLog() {
        guard activeLogBinRecorder == nil else {
            return
        }

        let dirName = dateFormatter.string(from: Date())
        currentLogDirectory = logsURL.appendingPathComponent(dirName)
        guard let currentLogDirectory = currentLogDirectory else {
            return
        }

        if !FileManager.default.fileExists(atPath: currentLogDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: currentLogDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create log directory \(currentLogDirectory) \(error.localizedDescription)")
            }
        }
        let logBinConfig = LogBinRecorderConfig(currentLogDirectory)
        activeLogBinRecorder = ULog.redirectToLogBin(config: logBinConfig)
        setStreamDbgEnv()
    }

    /// Stops Log.
    static func stopLog() {
        currentLogDirectory = nil
        activeLogBinRecorder = nil
    }

    /// Creates a stream debug path.
    static func createStreamDebugPath() {
        if !streamDebugPathExists() {
            try? FileManager.default.createDirectory(atPath: streamDbgPath,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
    }

    /// Returns true if stream debug path exists.
    static func streamDebugPathExists() -> Bool {
        return FileManager.default.fileExists(atPath: streamDbgPath)
    }

    /// Returns a list of files containing logs.
    static func listLogFiles() -> [URL] {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: logsURL, includingPropertiesForKeys: nil, options: [])
            return directoryContents
        } catch {
            ULog.e(debugTag, "listLogFiles - Error \(error)")
            return []
        }
    }

    /// Remove a log file.
    ///
    /// - Parameters:
    ///     - fileUrl: url of the file
    ///     - completionOK: callback called when file is deleted
    static func removeLogUrl(fileURL: URL, srcVC: UIViewController, completionOK: @escaping () -> Void) {
        let alertController = UIAlertController(title: L10n.commonConfirmation, message: L10n.debugLogConfirmDelete, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: L10n.commonDelete, style: .destructive, handler: { _ in
            do {
                try FileManager.default.removeItem(at: fileURL)
                completionOK()
            } catch {
                ULog.e(debugTag, "Failed to delete file \(fileURL.lastPathComponent) - \(error)" )
            }
        }))
        alertController.addAction(UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil))
        srcVC.present(alertController, animated: true, completion: nil)
    }

    /// Rename a log file.
    ///
    /// - Parameters:
    ///     - fileUrl: url of the file
    ///     - withLastComponent: last component
    static func renameLogFile(fromUrl: URL, withLastComponent: String) {
        var newUrl = fromUrl.deletingLastPathComponent()
        newUrl.appendPathComponent(withLastComponent, isDirectory: false)
        do {
            try FileManager.default.moveItem(at: fromUrl, to: newUrl)
        } catch {
            ULog.e(debugTag, "Rename from \(fromUrl) to \(newUrl) - Error \(error)")
        }
    }

    /// Prepares file to share for logs at a given URL.
    ///
    /// If the given URL is a directory, this method creates an archive file
    /// containing the directory content.
    /// If the given URL is a file, this methods returns the URL itself. The
    /// file can be shared directly.
    ///
    /// - Parameters:
    ///    - url: path to logs
    /// - Returns: file to share, `nil` if an error occured
    static func fileToShare(for url: URL) -> URL? {
        guard url.isDirectory else {
            return url
        }

        var archiveUrl: URL?
        var error: NSError?
        let fileManager = FileManager.default
        let coordinator = NSFileCoordinator()
        // zip directory content
        coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &error) { (zipUrl) in
            // move archive file to a temporary folder
            let tmpUrl = try? fileManager.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: zipUrl,
                create: true
            ).appendingPathComponent(url.lastPathComponent.appending(".zip"))
            tmpUrl.map { try? fileManager.moveItem(at: zipUrl, to: $0) }
            archiveUrl = tmpUrl
        }
        return archiveUrl
    }

    /// Check if app is launched bu XCUITest
    static func isUiTest() -> Bool {
        ProcessInfo.processInfo.environment["isUITest"] == "1"
    }
}

// MARK: - Private Funcs
private extension ParrotDebug {
    /// Set new debug environnement for stream.
    static func setStreamDbgEnv() {
        if streamDebugPathExists() {
            setenv("VSTRM_DBG_DIR", streamDbgPath, 1)
            // Set VSTRM_DBG_FLAGS to the VSTRM_DBG_FLAG_RECEIVER_STREAM value according to the libvideo-streaming"
            setenv("VSTRM_DBG_FLAGS", "4", 1)
        }
    }

    /// Returns the log directory url.
    static var logsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("log")
    }

    /// Date formatter for directory name.
    static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }
}
