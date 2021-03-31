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

enum PanoramaStatus {
    case notGenerated
    case generated
}

enum PanoRatio: String {
    case ratio1by1
    case ratio2by1
    case ratio4by3
    case ratio3by2
    case ratio16by9

    var title: String {
        switch self {
        case .ratio1by1:
            return "1:1"
        case .ratio2by1:
            return "2:1"
        case .ratio4by3:
            return "4:3"
        case .ratio3by2:
            return "3:2"
        case .ratio16by9:
            return "16:9"
        }
    }

    static var preset: PanoRatio {
        return .ratio16by9
    }

    /// Returns PhotoPanoViewAspectRatio associated to ratio.
    var photoPanoViewAspectRatio: PhotoPanoViewAspectRatio {
        switch self {
        case .ratio1by1:
            return ._1_1
        case .ratio2by1:
            return ._2_1
        case .ratio4by3:
            return ._4_3
        case .ratio3by2:
            return ._3_2
        case .ratio16by9:
            return ._16_9
        }
    }
}

enum PanoramaMediaType: String, CaseIterable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case superWide = "SuperWide"
    // 360 degrees :
    case sphere = "Sphere"
    case tinyPlanet = "TinyPlanet"
    case tunnel = "Tunnel"

    // MARK: - Internal Properties
    /// Returns image associated to type.
    var image: UIImage {
        switch self {
        case .sphere:
            return Asset.Gallery.Panorama.icSphere.image
        case .tinyPlanet:
            return Asset.Gallery.Panorama.icTinyPlanet.image
        case .tunnel:
            return Asset.Gallery.Panorama.icTunnel.image
        case .horizontal:
            return Asset.BottomBar.CameraSubModes.icPanoHorizontal.image
        case .vertical:
            return Asset.BottomBar.CameraSubModes.icPanoVertical.image
        case .superWide:
            return Asset.BottomBar.CameraSubModes.icPanoWide.image
        }
    }

    // Returns highlighted image associated to type.
    var highlightedImage: UIImage? {
        switch self {
        case .sphere:
            return Asset.Gallery.Panorama.icSphereHighlighted.image
        case .tinyPlanet:
            return Asset.Gallery.Panorama.icTinyPlanetHighlighted.image
        case .tunnel:
            return Asset.Gallery.Panorama.icTunnelHighlighted.image
        // TODO: add icon when design will be available
        case .horizontal:
            return nil
        case .vertical:
            return nil
        case .superWide:
            return nil
        }
    }

    /// Returns generation text associated to type.
    var generatingText: String {
        switch self {
        case .sphere:
            return L10n.galleryPanoramaGeneratingSphere
        case .tinyPlanet:
            return L10n.galleryPanoramaGeneratingTinyPlanet
        case .tunnel:
            return L10n.galleryPanoramaGeneratingTunnel
        case .superWide:
            return L10n.galleryPanoramaGeneratingSuperwide
        case .horizontal:
            return L10n.galleryPanoramaGeneratingHorizontal
        case .vertical:
            return L10n.galleryPanoramaGeneratingVertical
        }
    }

    /// Returns PhotoPanoPreset associated to type.
    var toPanoramaPreset: PhotoPanoPreset {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        case .sphere:
            return .sphere
        case .tinyPlanet:
            return .planet
        case .tunnel:
            return .tunnel
        case .superWide:
            return .superWide
        }
    }

    /// Returns panorama optimal width for a quality.
    ///
    /// - Parameters:
    ///    - quality: quality.
    func width(forQuality quality: PanoramaQuality) -> Int32 {
        let isLowResolution = DeviceUtils.isLowPanoramaResolution
        switch self {
        case .horizontal where quality == .good,
             .sphere where quality == .good:
            return isLowResolution ? 4224 : 6144
        case .horizontal where quality == .excellent,
             .sphere where quality == .excellent:
            return 8000
        case .superWide where quality == .good:
            return isLowResolution ? 3456 : 4896
        case .superWide where quality == .excellent:
            return 6528
        case .tinyPlanet where quality == .good,
             .tunnel where quality == .good:
            return isLowResolution ? 3072 : 4224
        case .tinyPlanet where quality == .excellent,
             .tunnel where quality == .excellent:
            return 5632
        case .vertical where quality == .good:
            return isLowResolution ? 2112 : 3072
        case .vertical where quality == .excellent:
            return 4000
        default:
            return 0
        }
    }

    /// Returns panorama optimal height for a quality.
    ///
    /// - Parameters:
    ///    - quality: quality.
    func height(forQuality quality: PanoramaQuality) -> Int32 {
        let isLowResolution = DeviceUtils.isLowPanoramaResolution
        switch self {
        case .horizontal where quality == .good,
             .sphere where quality == .good:
            return isLowResolution ? 2112 : 3072
        case .horizontal where quality == .excellent,
             .sphere where quality == .excellent:
            return 4000
        case .superWide where quality == .good:
            return isLowResolution ? 2592 : 3672
        case .superWide where quality == .excellent:
            return 4896
        case .tinyPlanet where quality == .good,
             .tunnel where quality == .good:
            return isLowResolution ? 3072 : 4224
        case .tinyPlanet where quality == .excellent,
             .tunnel where quality == .excellent:
            return 5632
        case .vertical where quality == .good:
            return isLowResolution ? 4224 : 6144
        case .vertical where quality == .excellent:
            return 8000
        default:
            return 0
        }
    }
}
