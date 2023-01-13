//    Copyright (C) 2022 Parrot Drones SAS
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

import GroundSdk

extension URL {
    /// Allows access to security scoped resources during the lifetime of a given block.
    ///
    /// - Parameters:
    ///   - access: the access block
    ///   - url: the url that can be accessed during the block
    /// - Returns the `access` block return type.
    func accessResource<U>(_ access: (_ url: Self) throws -> U) rethrows -> U {
        // Allows to access Files app's ressources (files outside the app sandbox).
        let isAccessingSecurityRessource = self.startAccessingSecurityScopedResource()
        defer {
            // Stop, if needed, the granted security access.
            if isAccessingSecurityRessource { self.stopAccessingSecurityScopedResource() }
        }
        return try access(self)
    }
}

/// Utility extension for `MavlinkStandard.MavlinkFiles`.
public extension MavlinkStandard.MavlinkFiles {

    /// Parses a MAVLink file into a list of commands.
    ///
    /// Any malformed command is simply ignored and removed from the resulting array. If the
    /// given file is not properly formatted, this method returns an empty list.
    ///
    /// - Parameter fileUrl: the file to read
    /// - Returns: the command list extracted from the file
    ///
    /// - Description: This method must be used when accessing a file outside the app sandbox (e.g. Files app).
    static func parse(fileUrl: URL) throws -> [MavlinkStandard.MavlinkCommand] {
        // Grant, if needed, the access to the file then return its content.
        let mavlinkString = try fileUrl.accessResource { url in
            try String(contentsOf: url, encoding: .utf8)
        }
        // Retunrs the parsed file content.
        return try parse(mavlinkString: mavlinkString)
    }
}

/// Utility extension for `MavlinkFilesV1`.
public extension MavlinkFiles {

    /// Parses a MAVLink file into a list of commands.
    ///
    /// Any malformed command is simply ignored. If the given file is not properly formatted, this method returns an
    /// empty list.
    ///
    /// - Parameter fileUrl: the file to read
    /// - Returns: the command list extracted from the file
    ///
    /// - Description: This method must be used when accessing a file outside the app sandbox (e.g. Files app).
    static func parse(fileUrl: URL) -> [MavlinkCommand] {
        // Grant, if needed, the access to the file then return its content.
        let mavlinkString = fileUrl.accessResource { url in
            try? String(contentsOf: url, encoding: .utf8)
        }
        // Ensure file exists.
        guard let string = mavlinkString else { return [] }
        // Returns the parsed file content.
        return parse(mavlinkString: string)
    }
}
