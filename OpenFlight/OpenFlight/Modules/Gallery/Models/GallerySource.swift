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

import UIKit

/// Gallery source type.
enum GallerySourceType: CaseIterable {
    case unknown
    case droneSdCard
    case droneInternal
    case mobileDevice
    var image: UIImage? {
         switch self {
         case .droneSdCard:
            return Asset.Dashboard.icCardMini.image
         case .droneInternal:
            return Asset.Dashboard.icInternalMini.image
         case .mobileDevice:
            return Asset.Dashboard.icPhoneMini.image
         default:
            return nil
         }
    }

    var title: String {
        switch self {
        case .droneSdCard:
            return L10n.gallerySourceDroneSd
        case .droneInternal:
            return L10n.gallerySourceDroneInternal
        case .mobileDevice:
            return L10n.gallerySourceLocalMemory
        default:
            return ""
        }
    }

    var panoramaCopyTitle: String {
        switch self {
        case .droneSdCard:
            return L10n.galleryPanoramaSdCopy
        case .droneInternal:
            return L10n.galleryPanoramaInternalCopy
        default:
            return ""
        }
    }

    func deleteConfirmMessage(count: Int) -> String {
        switch self {
        case .droneSdCard,
             .droneInternal:
            return count > 1
                ? L10n.galleryRemoveDroneMemoryConfirmPlural
                : L10n.galleryRemoveDroneMemoryConfirm
        case .mobileDevice:
            return count > 1
                ? L10n.galleryRemoveLocalMemoryConfirmPlural
                : L10n.galleryRemoveLocalMemoryConfirm
        default:
            return ""
        }
    }

    func deleteErrorMessage(count: Int) -> String {
        switch self {
        case .droneSdCard,
             .droneInternal:
            return count > 1
                ? L10n.galleryRemoveDroneMemoryErrorPlural
                : L10n.galleryRemoveDroneMemoryError
        case .mobileDevice:
            return count > 1
                ? L10n.galleryRemoveLocalMemoryErrorPlural
                : L10n.galleryRemoveLocalMemoryError
        default:
            return ""
        }
    }

    func deleteResourceConfirmMessage(count: Int) -> String {
        switch self {
        case .droneSdCard,
             .droneInternal:
            return L10n.galleryRemoveResourceDroneMemoryConfirm(count)
        case .mobileDevice:
            return L10n.galleryRemoveResourceLocalMemoryConfirm(count)
        default:
            return ""
        }
    }

    var isDroneSource: Bool {
        switch self {
        case .droneInternal, .droneSdCard:
            return true
        default:
            return false
        }
    }
}

/// Extension for debug description.
extension GallerySourceType: CustomStringConvertible {
    var description: String {
        switch self {
        case .droneInternal: return "droneInternal"
        case .droneSdCard: return "droneSdCard"
        case .mobileDevice: return "mobileDevice"
        case .unknown: return "unknown"
        }
    }
}

/// Gallery source model.
struct GallerySource {
    var type: GallerySourceType
    var storageUsed: Double
    var storageCapacity: Double
    var isOffline: Bool

    var image: UIImage? {
        switch type {
        case .droneSdCard:
            return Asset.Gallery.droneSd.image
        case .droneInternal:
            return Asset.Gallery.droneInternalMemory.image
        case .mobileDevice:
            return Asset.Dashboard.icPhoneLight.image
        default:
            return nil
        }
    }
}
