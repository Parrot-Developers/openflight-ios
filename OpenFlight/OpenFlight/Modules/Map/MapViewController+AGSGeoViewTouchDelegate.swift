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

import ArcGIS

extension MapViewController: AGSGeoViewTouchDelegate {
    open func geoView(_ geoView: AGSGeoView,
                      didTapAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint) {
        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        // The workaround consist of declaring a local optional variable and then testing it for
        // nullity.
        let potentiallyNullMapPoint: AGSPoint? = mapPoint
        guard !screenPoint.isOriginPoint, potentiallyNullMapPoint != nil else { return }

        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleTap(geoView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
        case .standard:
            identify(screenPoint: screenPoint) { [weak self] in
                self?.customControls?.handleCustomMapTap(mapPoint: mapPoint, identifyResult: $0)
            }
        default:
            break
        }
    }

    open func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        // The workaround consist of declaring a local optional variable and then testing it for
        // nullity.
        let potentiallyNullMapPoint: AGSPoint? = mapPoint
        guard !screenPoint.isOriginPoint, potentiallyNullMapPoint != nil else { return }

        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleLongPress(geoView, didLongPressAtScreenPoint: screenPoint, mapPoint: mapPoint)
        case .standard:
            identify(screenPoint: screenPoint) { [weak self] in
                self?.customControls?.handleCustomMapLongPress(mapPoint: mapPoint, identifyResult: $0)
            }
        default:
            break
        }
    }

    open func geoView(_ geoView: AGSGeoView,
                      didTouchDownAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint,
                      completion: @escaping (Bool) -> Void) {
        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        // The workaround consist of declaring a local optional variable and then testing it for
        // nullity.
        let potentiallyNullMapPoint: AGSPoint? = mapPoint
        guard !screenPoint.isOriginPoint, potentiallyNullMapPoint != nil else { return }

        viewModel.disableAutoCenter(true)
        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleTouchDown(geoView,
                                      didTouchDownAtScreenPoint: screenPoint,
                                      mapPoint: mapPoint,
                                      completion: completion)
        case .standard:
            identify(screenPoint: screenPoint) { [weak self] in
                self?.customControls?.handleCustomMapTouchDown(mapPoint: mapPoint, identifyResult: $0, completion: completion)
            }
        default:
            completion(false)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        // The workaround consist of declaring a local optional variable and then testing it for
        // nullity.
        let potentiallyNullMapPoint: AGSPoint? = mapPoint
        guard !screenPoint.isOriginPoint, potentiallyNullMapPoint != nil else { return }

        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleTouchDrag(geoView, didTouchDragToScreenPoint: screenPoint, mapPoint: mapPoint)
        case .standard:
            customControls?.handleCustomMapDrag(mapPoint: mapPoint)
        default:
            break
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchUpAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        // The workaround consist of declaring a local optional variable and then testing it for
        // nullity.
        let potentiallyNullMapPoint: AGSPoint? = mapPoint
        guard !screenPoint.isOriginPoint, potentiallyNullMapPoint != nil else { return }

        switch currentMapMode {
        case .flightPlanEdition:
            flightPlanHandleTouchUp(geoView, didTouchUpAtScreenPoint: screenPoint, mapPoint: mapPoint)
        case .standard:
            customControls?.handleCustomMapTouchUp(mapPoint: mapPoint)
        default:
            break
        }
    }
}
