//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import SwiftyUserDefaults

/// Helpers for HDR configuration.
public extension Camera2Editor {
    /// Enable hdr.
    func enableHdr(camera: Camera2?) {
        handleHdr(camera, enable: true)
    }

    /// Disable hdr.
    func disableHdr(camera: Camera2?) {
        handleHdr(camera, enable: false)
    }

    /// Enable or disable hdr.
    ///
    /// - Parameters:
    ///    - camera: Current camera.
    ///    - enable: Boolean that specify if we want to enable or disable hdr.
    func handleHdr(_ camera: Camera2?, enable: Bool) {
        guard let strongCamera = camera else { return }

        switch strongCamera.mode {
        case .photo:
            // Photo can only do HDR 8.
            self[Camera2Params.photoDynamicRange]?.value = enable ? .hdr8 : .sdr
        case .recording:
            let newHdrValue: Camera2DynamicRange
            // If we already have an HDR defaults.

            if let defaultsHDRString = Defaults.highDynamicRangeSetting,
               let defaultsHDR = Camera2DynamicRange(rawValue: defaultsHDRString) {
                newHdrValue = defaultsHDR
            } else {
                let videoEncoding = camera?.config[Camera2Params.videoRecordingCodec]?.value
                newHdrValue = videoEncoding == .h265 ? Camera2DynamicRange.hdr10 : Camera2DynamicRange.hdr8
            }

            self[Camera2Params.videoRecordingDynamicRange]?.value = enable ? newHdrValue : .sdr
            Defaults.highDynamicRangeSetting = newHdrValue.rawValue
        default:
            break
        }
    }
}
