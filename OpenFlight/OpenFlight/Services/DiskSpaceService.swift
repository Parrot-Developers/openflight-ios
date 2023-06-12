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
import Combine
import GroundSdk

fileprivate extension ULogTag {
    static let tag = ULogTag(name: "diskSpaceService")
}

public enum DiskSpaceStatus {
    case available
    case warning
    case critical
}

public protocol DiskSpaceService {
    var status: DiskSpaceStatus { get }
    var statusPublisher: AnyPublisher<DiskSpaceStatus, Never> { get }

    func checkDiskSpaceStatus()
}

public class DiskSpaceServiceImpl: DiskSpaceService {
    // MARK: DiskSpaceService Protocol
    public var status: DiskSpaceStatus { statusSubject.value }
    public var statusPublisher: AnyPublisher<DiskSpaceStatus, Never> {
        statusSubject
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: Private
    private enum Constants {
        static let recurrencyCheckSeconds: TimeInterval = 60 * 5
        static let criticalThresholdBytes: Int64 = 250_000_000
        static let warningThresholdBytes: Int64 = 500_000_000
    }
    private var statusSubject = CurrentValueSubject<DiskSpaceStatus, Never>(.available)
    private var recurrencyTimer: Timer?
    private var totalDiskSpaceBytes: Int64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
              let space = (systemAttributes[FileAttributeKey.systemSize] as? NSNumber)?.int64Value else {
            return 0
        }
        return space
    }
    private var freeDiskSpaceBytes: Int64 {
        /*
         Total available capacity in bytes for "Important" resources,
         including space expected to be cleared by purging non-essential and cached resources.
         "Important" means something that the user or application clearly expects to be present on the local system,
         but is ultimately replaceable.
         This would include items that the user has explicitly requested via the UI,
         and resources that an application requires in order to provide functionality.
         */
        let capacity = try? URL(fileURLWithPath: NSHomeDirectory() as String)
            .resourceValues(forKeys: [URLResourceKey.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage
        return capacity ?? 0
    }
    private var usedDiskSpaceBytes: Int64 {
        return totalDiskSpaceBytes - freeDiskSpaceBytes
    }

    // MARK: Init
    init() {
        startRecurrencyCheck()
    }

    // MARK: DiskSpaceService Protocol
    @objc public func checkDiskSpaceStatus() {
        switch freeDiskSpaceBytes {
        case _ where freeDiskSpaceBytes < Constants.criticalThresholdBytes:
            statusSubject.value = .critical
        case _ where freeDiskSpaceBytes < Constants.warningThresholdBytes:
            statusSubject.value = .warning
        default:
            statusSubject.value = .available
        }

        let freeMb = formatInMB(freeDiskSpaceBytes)
        let usedMb = formatInMB(usedDiskSpaceBytes)
        let totalMb = formatInMB(totalDiskSpaceBytes)
        ULog.i(.tag, "Check disk space status: \(status) - \(freeMb) available out of \(totalMb) (\(usedMb) used)")
    }
}

// MARK: - Private extension
private extension DiskSpaceServiceImpl {
    func startRecurrencyCheck() {
        recurrencyTimer?.invalidate()
        recurrencyTimer = Timer.scheduledTimer(timeInterval: Constants.recurrencyCheckSeconds,
                                               target: self,
                                               selector: #selector(self.checkDiskSpaceStatus),
                                               userInfo: nil,
                                               repeats: true)
        recurrencyTimer?.fire()
    }

    func formatInMB(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = ByteCountFormatter.Units.useMB
        formatter.countStyle = ByteCountFormatter.CountStyle.decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes) as String
    }
}
