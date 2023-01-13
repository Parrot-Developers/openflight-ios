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

    // MARK: - MAVLink
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

    // MARK: - Plan
    /// Returns the URL where the flight plan's Plan file is expected to be written.
    ///
    /// - Parameter flightPlan: the flight plan
    /// - Returns the Plan file `URL`
    func planFileUrl(for flightPlan: FlightPlanModel) -> URL

    /// Stores in filesystem the Plan file to upload to the Drone.
    ///
    /// - Parameters:
    ///   - flightPlan: the flight plan
    ///   - data: the data to write in the file
    /// - Throws an error in case of file writing failure
    func savePlanFile(of flightPlan: FlightPlanModel, with data: Data) throws

    /// Removes an FP's Plan file saved in filesystem.
    ///
    /// - Parameter flightPlan: the flight plan
    /// - Throws an error in case of file removing failure
    func removePlanFile(of flightPlan: FlightPlanModel) throws

    // MARK: - Debug / Test
    func createFilesDirectory(for flightPlan: FlightPlanModel,
                              planFileData: Data?,
                              mavlinkFileData: Data?) throws -> URL
}

private extension ULogTag {
    static let tag = ULogTag(name: "FlightPlanFilesManager")
}

open class FlightPlanFilesManagerImpl {

    /// The user's temporary directory is used as root directory for the Plan/Mavlink files.
    static let filesRootDirectory = FileManager.default.temporaryDirectory

    // MARK: - Private Enums
    private enum Constants {
        // MARK: - MAVLink
        static let mavlinkExtension: String = "mavlink"
        static let tmpMavlinksFolderUrl: URL = filesRootDirectory.appendingPathComponent("tmp-mavlinks", isDirectory: true)
        // Debug/Test Purpose Only.
        static var exportedMavlinksFolderUrl: URL {
            FileManager.default
            // swiftlint:disable:next force_unwrapping
                .urls(for: .documentDirectory, in: .userDomainMask).first!
                .appendingPathComponent("mavlink")
        }

        // MARK: - Plan
        static let planExtension: String = "plan"
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

    // MARK: - Plan
    public func planFileUrl(for flightPlan: FlightPlanModel) -> URL {
        Self.filesRootDirectory
            .appendingPathComponent(flightPlan.uuid)
            .appendingPathExtension(Constants.planExtension)
    }

    public func savePlanFile(of flightPlan: FlightPlanModel, with data: Data) throws {
        let fileUrl = planFileUrl(for: flightPlan)
        try? FileManager.default.removeItem(at: fileUrl)
        try data.write(to: fileUrl)
    }

    public func removePlanFile(of flightPlan: FlightPlanModel) throws {
        let fileUrl = planFileUrl(for: flightPlan)
        try FileManager.default.removeItem(at: fileUrl)
    }

    // MARK: - Debug / Test
    public func createFilesDirectory(for flightPlan: FlightPlanModel,
                                     planFileData: Data?,
                                     mavlinkFileData: Data?) throws -> URL {
        let directoryUrl = Self.filesRootDirectory.appendingPathComponent(flightPlan.uuid)
        try FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: true)
        // Build URLs
        let planUrl = directoryUrl
            .appendingPathComponent(flightPlan.customTitle)
            .appendingPathExtension(Constants.planExtension)
        let mavlinkUrl = directoryUrl
            .appendingPathComponent(flightPlan.customTitle)
            .appendingPathExtension(Constants.mavlinkExtension)
        let fpUrl = directoryUrl
            .appendingPathComponent("FlightPlanDescription")
            .appendingPathExtension("txt")
        let planPrettyJsonUrl = directoryUrl
            .appendingPathComponent("Plan")
            .appendingPathExtension("json")
        let mavlinkCmdsUrl = directoryUrl
            .appendingPathComponent("MAVLinkCommands")
            .appendingPathExtension("txt")
        // Save files
        try? planFileData?.write(to: planUrl)
        try? mavlinkFileData?.write(to: mavlinkUrl)
        try? "\(flightPlan.lightDescription)".data(using: .utf8)?.write(to: fpUrl)
        try? planFileData?.prettyJson?.write(to: planPrettyJsonUrl)
        try? mavlinkFileData?.mavlinkCommandsFileData?.write(to: mavlinkCmdsUrl)
        return directoryUrl
    }
}

// MARK: - Debug / Test
// Quick & Dirty temp. code used for DBG purpose.
extension Data {
    /// The data Pretty JSON representation of the current Data.
    var prettyJson: Data? {
        if let object = try? JSONSerialization.jsonObject(with: self, options: []) {
            return try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        }
        return nil
    }
    /// Returns a more readable list of parsed mavlink commands.
    var mavlinkCommandsFileData: Data? {
        guard let dataString = String(data: self, encoding: .utf8),
              let commands = try? MavlinkStandard.MavlinkFiles.parse(mavlinkString: dataString)
        else { return nil }
        var cmd = "\(commands)".replacingOccurrences(of: "GroundSdk.MavlinkStandard.", with: "")
        _ = cmd.removeFirst()
        _ = cmd.removeLast()
        return cmd.components(separatedBy: ", ")
            .enumerated()
            .map { "\($0.0): \($0.1)" }
            .joined(separator: "\n")
            .data(using: .utf8)
    }
}

extension FlightPlanModel {
    /// The Flight Plan description without some useless fields (e.g. thumbnail)
    /// (Quick and dirty implementation)
    var lightDescription: String {
        var flightPlan = self
        flightPlan.thumbnail = nil
        var description = "\(flightPlan)"
        _ = description.popLast()
        description = String(description.suffix(description.count - "FlightPlanModel(".count))
        description = description.replacingOccurrences(of: ", ", with: ",\n")
        description = description.replacingOccurrences(of: "dataSetting:", with: "\ndataSetting:")
        description = description.replacingOccurrences(of: "parrotCloudUploadUrl:", with: "\nparrotCloudUploadUrl:")
        return description
    }
}
