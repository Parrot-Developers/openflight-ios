//    Copyright (C) 2021 Parrot Drones SAS
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

/// Manager for flight plan files
public protocol FlightPlanFilesManager {

    /// Build the URL where the flight plan mavlink file is expected to be written
    /// - Parameter flightPlan: the flight plan
    func defaultUrl(flightPlan: FlightPlanModel) -> URL

    func isMavlinkUrl(_ url: URL?) -> Bool

    /// Writes mavlink file to FP's default URL if any
    /// - Parameter flightPlan: flight plan
    func writeFile(of flightPlan: FlightPlanModel) throws

    /// Writes mavlink file to export folder
    /// - Parameter flightPlan: flight plan
    func exportFile(of flightPlan: FlightPlanModel) throws

    /// Delete the mavlink file of the FP if it exists
    /// - Parameter flightPlan: flight plan
    func deleteMavlink(of flightPlan: FlightPlanModel)

    /// Generate an URL to store a temporary mavlink file
    func urlForTemporaryMavlink() -> URL

    /// Clear temporary mavlink files
    func clearTemporaryMavlinks()
}

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanFilesManager")
}

open class FlightPlanFilesManagerImpl {

    private enum Constants {
        static let mavlinkExtension: String = "mavlink"
        static let tmpMavlinksFolderUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent("tmp-mavlinks", isDirectory: true)
        static var exportedMavlinksFolderUrl: URL {
            let fileManager = FileManager.default
            let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentPath.appendingPathComponent("mavlink")
        }

    }

    init() {
        clearTemporaryMavlinks()
    }

    private func createTemporaryMavlinksDirectory() {
        if !FileManager.default.fileExists(atPath: Constants.tmpMavlinksFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(at: Constants.tmpMavlinksFolderUrl, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                ULog.i(.tag, "Failed to create temporary mavlink files directory: " + error.localizedDescription)
            }
        }
    }

    private func createExportedMavlinksDirectory() {
        if !FileManager.default.fileExists(atPath: Constants.exportedMavlinksFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(at: Constants.exportedMavlinksFolderUrl, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                ULog.i(.tag, "Failed to create exported mavlink files directory: " + error.localizedDescription)
            }
        }
    }
}

extension FlightPlanFilesManagerImpl: FlightPlanFilesManager {
    public func clearTemporaryMavlinks() {
        do {
            try FileManager.default.removeItem(at: Constants.tmpMavlinksFolderUrl)
        } catch let error {
            ULog.i(.tag, "Failed to remove temporary mavlink files directory: " + error.localizedDescription)
        }
        createTemporaryMavlinksDirectory()
    }

    public func defaultUrl(flightPlan: FlightPlanModel) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(flightPlan.uuid)
            .appendingPathExtension(Constants.mavlinkExtension)
    }

    public func exportUrl(flightPlan: FlightPlanModel) -> URL {
        Constants.exportedMavlinksFolderUrl
            .appendingPathComponent(flightPlan.customTitle)
            .appendingPathExtension(Constants.mavlinkExtension)
    }

    public func isMavlinkUrl(_ url: URL?) -> Bool {
        url?.pathExtension == Constants.mavlinkExtension
    }

    public func writeFile(of flightPlan: FlightPlanModel) throws {
        let destination = defaultUrl(flightPlan: flightPlan)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try flightPlan.dataSetting?.mavlinkDataFile?.write(to: destination)
    }

    public func exportFile(of flightPlan: FlightPlanModel) throws {
        let destination = exportUrl(flightPlan: flightPlan)
        if !FileManager.default.fileExists(atPath: Constants.exportedMavlinksFolderUrl.path) {
            createExportedMavlinksDirectory()
        }

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try flightPlan.dataSetting?.mavlinkDataFile?.write(to: destination)
    }

    public func deleteMavlink(of flightPlan: FlightPlanModel) {
        let destination = defaultUrl(flightPlan: flightPlan)
        if FileManager.default.fileExists(atPath: destination.path) {
            do {
                try FileManager.default.removeItem(at: destination)
            } catch {
                ULog.e(.tag,
                       "Could not delete mavlink file of flight plan \(flightPlan.uuid): "
                        + error.localizedDescription)
            }
        }
    }

    public func urlForTemporaryMavlink() -> URL {
        Constants.tmpMavlinksFolderUrl
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(Constants.mavlinkExtension)
    }
}
