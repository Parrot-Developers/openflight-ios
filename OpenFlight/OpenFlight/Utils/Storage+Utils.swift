//
//  Copyright (C) 2020 Parrot Drones SAS.
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

/// Utilities to handle storage associated functions.

final class StorageUtils {

    enum Constants {
        static let bytesPerGigabyte = 1000000000
    }

    /// Returns remaining video recording time.
    ///
    /// - Parameters:
    ///    - availableSpace: space available on storage
    ///    - bitrate: current recording bitrate
    /// - Returns: a time interval containing remaining recording time
    static func remainingTime(availableSpace: Int64?, bitrate: Int64?) -> TimeInterval? {
        guard let bitrate = bitrate, let availableSpace = availableSpace, bitrate > 0 else {
            return nil
        }
        return TimeInterval(availableSpace * Int64(8) / bitrate)
    }

    /// Returns the size of an int in byte.
    /// Example : 1.2 Gb.
    ///
    /// - Parameters:
    ///     - size: size as UInt64 value
    /// - Returns: size as string
    static func sizeForFile(size: UInt64) -> String {
        let sizeFormatter = ByteCountFormatter()
        sizeFormatter.countStyle = .file
        sizeFormatter.allowedUnits = [.useGB, .useMB, .useKB]
        sizeFormatter.allowsNonnumericFormatting = false
        return formatSize(size: sizeFormatter.string(fromByteCount: Int64(size)).capitalized,
                          isIncludingUnit: true)
    }
}

private extension StorageUtils {
    /// Format size helper.
    ///
    /// - Parameters:
    ///     - size: size as String value
    ///     - isIncludingUnit: includes unit or not
    /// - Returns: size as string
    static func formatSize(size: String, isIncludingUnit: Bool) -> String {
        guard let space = size.split(separator: " ").first?.replacingOccurrences(of: ",", with: "."),
            let doubleSpace = Double(space)?.rounded(toPlaces: 1) else {
                return size
        }

        if isIncludingUnit, let unit = size.split(separator: " ").last {
            return "\(doubleSpace) \(unit)"
        } else {
            return "\(doubleSpace)"
        }
    }
}
