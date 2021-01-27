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

/// `Camera2HyperlapseValue` Extension used to display camera hyperlapse sub-modes in bottom bar.
extension Camera2HyperlapseValue: BarItemSubMode {

    public var image: UIImage? {
        return Asset.BottomBar.CameraModes.icCameraModeHyperlapse.image
    }

    public static let allValues: [BarItemMode] = [Camera2HyperlapseValue.ratio15,
                                           Camera2HyperlapseValue.ratio30,
                                           Camera2HyperlapseValue.ratio60,
                                           Camera2HyperlapseValue.ratio120,
                                           Camera2HyperlapseValue.ratio240]

    public var key: String {
        return rawValue
    }

    public var title: String {
        switch self {
        case .ratio15:
            return L10n.cameraSubModeHyperlapseRatio15
        case .ratio30:
            return L10n.cameraSubModeHyperlapseRatio30
        case .ratio60:
            return L10n.cameraSubModeHyperlapseRatio60
        case .ratio120:
            return L10n.cameraSubModeHyperlapseRatio120
        case .ratio240:
            return L10n.cameraSubModeHyperlapseRatio240
        }
    }

    public var value: Int? {
        return Int(rawValue)
    }

    public var shutterText: String? {
        return title
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.hyperlapseRatio.name
    }
}
