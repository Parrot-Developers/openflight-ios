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

import UIKit

/// Utility extension for `UIDevice`.

// MARK: - Private Enums
private enum Constants {
    static let criticalLevel: Int = 10
    static let warningLevel: Int = 20
}

extension UIDevice {
    // MARK: - Internal Properties
    /// Returns alert level associated with current battery level.
    var alertLevel: AlertLevel {
        let currentLevel = Int(batteryLevel * 100)
        switch currentLevel {
        case ...Constants.criticalLevel:
            return .critical
        case Constants.criticalLevel...Constants.warningLevel:
            return .warning
        default:
            return .none
        }
    }

    /// Returns model for current battery level and associated alert.
    var batteryValueModel: BatteryValueModel {
        return BatteryValueModel(currentValue: Int(batteryLevel * 100), alertLevel: alertLevel)
    }

    /// Returns device total capacity in bytes.
    var capacityAsBytes: UInt64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let totalSize = (systemAttributes[.systemSize] as? NSNumber)?.uint64Value else {
                return 0
        }
        return totalSize
    }

    /// Returns device total capacity as a double.
    var capacityAsDouble: Double {
        return Double(capacityAsBytes) / Double(StorageUtils.Constants.bytesPerGigabyte)
    }

    /// Returns device total capacity as a string.
    var capacityAsString: String {
        return StorageUtils.sizeForFile(size: capacityAsBytes)
    }

    /// Returns device available storage space in bytes.
    var availableSpaceAsBytes: UInt64 {
        guard let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory() as String),
            let freeSize = (systemAttributes[.systemFreeSize] as? NSNumber)?.uint64Value else {
                return 0
        }
        return freeSize
    }

    /// Returns device total capacity as a double.
    var availableSpaceAsDouble: Double {
        return Double(availableSpaceAsBytes) / Double(StorageUtils.Constants.bytesPerGigabyte)
    }

    /// Returns device used storage space as a string.
    var availableSpaceAsString: String {
        return StorageUtils.sizeForFile(size: availableSpaceAsBytes)
    }

    /// Returns device used storage space in bytes.
    var usedStorageAsBytes: UInt64 {
        return capacityAsBytes - availableSpaceAsBytes
    }

    /// Returns device used storage space as a double.
    var usedStorageAsDouble: Double {
        return Double(usedStorageAsBytes) / Double(StorageUtils.Constants.bytesPerGigabyte)
    }

    /// Returns device used storage space as a string.
    var usedStorageAsString: String {
        return StorageUtils.sizeForFile(size: usedStorageAsBytes)
    }
}
