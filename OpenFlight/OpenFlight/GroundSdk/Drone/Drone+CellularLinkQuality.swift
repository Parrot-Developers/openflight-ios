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

import GroundSdk

/// Utility extension for `Drone`. Provides Cellular and NetworkControl helpers.

extension Drone {
    // MARK: - Internal Properties
    /// Returns true if cellular is available.
    var isCellularAvailable: Bool {
        return self.getPeripheral(Peripherals.cellular) != nil
            && self.isConnected
    }

    /// Returns cellular icon according to availability, technology and link quality.
    var cellularIcon: UIImage? {
        guard let cellular = self.getPeripheral(Peripherals.cellular),
            cellular.isModeAvailable,
            cellular.isRegistrationStatusOk,
            cellular.isNetworkStatusOk else {
                return Asset.Cellular.ic4GNoSignal.image
        }

        switch cellular.simStatus {
        case .ready:
            return self.iconByTechnology
        case .initializing:
            return Asset.Cellular.ic4GInactiveQuality5.image
        default:
            return Asset.Cellular.ic4GNoSignal.image
        }
    }
}

/// Private utility extension for `Drone`.
private extension Drone {
    // MARK: - Private Properties
    /// Returns cellular icon according to the current technology.
    var iconByTechnology: UIImage? {
        let networkControl = self.getPeripheral(Peripherals.networkControl)
        let cellular = self.getPeripheral(Peripherals.cellular)

        switch cellular?.technology {
        case .fourG,
             .fourGPlus:
            return networkControl?.cellularIcon4G
        case .gsm,
             .gprs,
             .edge:
            return Asset.Cellular.ic3GQuality1.image
        case .fiveG:
            return nil
        default:
            return networkControl?.cellularIcon3G
        }
    }
}

/// Private utility extension for `Cellular`.
private extension Cellular {
    // MARK: - Private Properties
    /// Returns true if cellular mode is available.
    var isModeAvailable: Bool {
        return self.mode.value == .data
    }

    /// Returns true if cellular registration status is okay.
    var isRegistrationStatusOk: Bool {
        return self.registrationStatus == .registeredHome
            || self.registrationStatus == .registeredRoaming
    }

    /// Returns true if cellular network status is activated.
    var isNetworkStatusOk: Bool {
        return self.networkStatus == .activated
    }
}

/// Private utility extension for `NetworkControl`.
private extension NetworkControl {
    // MARK: - Private Properties
    /// Returns cellular icon for 4G technology.
    var cellularIcon4G: UIImage? {
        // Boolean which is true when current link is cellular.
        let isCellularActive = self.currentLink == .cellular
        switch self.linkQuality {
        case 0:
            return isCellularActive
                ? Asset.Cellular.ic4GQuality2.image
                : Asset.Cellular.ic4GInactiveQuality1.image
        case 1:
            return isCellularActive
                ? Asset.Cellular.ic4GQuality3.image
                : Asset.Cellular.ic4GInactiveQuality2.image
        case 2:
            return isCellularActive
                ? Asset.Cellular.ic4GQuality4.image
                : Asset.Cellular.ic4GInactiveQuality3.image
        case 3:
            return isCellularActive
                ? Asset.Cellular.ic4GQuality5.image
                : Asset.Cellular.ic4GInactiveQuality4.image
        case 4:
            return isCellularActive
                ? Asset.Cellular.ic4GQuality6.image
                : Asset.Cellular.ic4GInactiveQuality5.image
        default:
            return Asset.Cellular.ic4GNoSignal.image
        }
    }

    /// Returns cellular icon for 3G technology.
    var cellularIcon3G: UIImage? {
        // Boolean which is true when current link is cellular.
        let isCellularActive = self.currentLink == .cellular
        switch self.linkQuality {
        case 0:
            return isCellularActive
                ? Asset.Cellular.ic3GQuality1.image
                : Asset.Cellular.ic3GInactiveQuality1.image
        case 1:
            return isCellularActive
                ? Asset.Cellular.ic3GQuality2.image
                : Asset.Cellular.ic3GInactiveQuality2.image
        case 2:
            return isCellularActive
                ? Asset.Cellular.ic3GQuality3.image
                : Asset.Cellular.ic3GInactiveQuality3.image
        case 3:
            return isCellularActive
                ? Asset.Cellular.ic3GQuality4.image
                : Asset.Cellular.ic3GInactiveQuality4.image
        case 4:
            return isCellularActive
                ? Asset.Cellular.ic3GQuality5.image
                : Asset.Cellular.ic3GInactiveQuality5.image
        default:
            return Asset.Cellular.ic3GNoSignal.image
        }
    }
}
