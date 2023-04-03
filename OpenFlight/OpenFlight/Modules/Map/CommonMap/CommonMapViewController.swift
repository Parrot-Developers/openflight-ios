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

import UIKit
import ArcGIS
import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "CommonMapViewController")
}

public enum CommonMapConstants {
    static let viewIdentifyTolerance: Double = 0
    static let viewIdentifyMaxResults: Int = 5
    static let minZoomLevel: Double = 30.0
    static let maxZoomLevel: Double = 2000000.0
    static let defaultLocation = CLLocationCoordinate2D(latitude: 48.879, longitude: 2.3673)
    public static let cameraDistanceToCenterLocation: Double = 1000
}

/// View controller for common map display.
open class CommonMapViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var navBarView: HudTopBarGradientView!
    @IBOutlet private weak var navBarStackView: UIStackView?
    @IBOutlet public weak var backButton: MainBackButton!

    // MARK: - Public Properties
    public var mapViewModel = CommonMapViewModel()
    public weak var splitControls: SplitControls?
    public var applyDefaultCentering: Bool = true
    public var ignoreCameraAdjustments: Bool = false
    public var lastValidPoints: (screen: CGPoint?, map: AGSPoint?)

    // Common vars used by the scene and the map to fix the camera altitude issue.
    public var hasBeenReset: Bool = false
    public var isNavigatingObserver: NSKeyValueObservation?

    // MARK: - Internal Properties
    private var cancellables = Set<AnyCancellable>()

    /// Configures ArcGIS license.
    func setArcGISLicense() {
        do {
            let result = try AGSArcGISRuntimeEnvironment.setLicenseKey(ServicesConstants.arcGisLicenseKey)
            print("License Result : \(result.licenseStatus)")
        } catch {
            ULog.e(.tag, "ArcGIS License error !")
        }
    }

    // MARK: - Override Funcs
    override open func viewDidLoad() {
        super.viewDidLoad()
        setArcGISLicense()
        setupNavBar()

        mapViewModel.isMiniMapPublisher.removeDuplicates()
            .sink { [weak self] isMiniMap in
                self?.miniMapChanged(value: isMiniMap)
            }.store(in: &cancellables)

        mapViewModel.mapTypePublisher
            .dropFirst()
            .sink { [weak self] _ in
                self?.setBaseMap()
            }.store(in: &cancellables)

        mapViewModel.networkReachablePublisher.removeDuplicates()
            .dropFirst()
            .sink { [weak self] reachable in
                if reachable {
                    self?.setBaseMap()
                }
            }.store(in: &cancellables)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapViewModel.isViewControllerVisible = true
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapViewModel.isViewControllerVisible = false
        applyDefaultCentering = false
    }

    /// Sets up the navigation bar (only contains back button).
    func setupNavBar() {
        navBarStackView?.isLayoutMarginsRelativeArrangement = true
    }

    // MARK: - Funcs to override
    open func miniMapChanged(value: Bool) {
        // to override
    }

    public func centerMap() {
        // to override
    }

    open func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        // to override
        completion(nil)
    }

    open func defaultCenteringDone() {
        // to override
    }

    open func setBaseMap() {
        // to override
    }

    open func update(mapRotation: Double) {
        // to override
    }

    func handleCustomMapTap(mapPoint: AGSPoint, screenPoint: CGPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        // to override
    }

    func handleCustomMapLongPress(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?) {
        // to override
    }

    func handleCustomMapTouchDown(mapPoint: AGSPoint, identifyResult: AGSIdentifyGraphicsOverlayResult?, completion: @escaping (Bool) -> Void) {
        // to override
        // if not override by default let the touches pass.
        completion(false)
    }

    func handleCustomMapDrag(mapPoint: AGSPoint) {
        // to override
    }

    func handleCustomMapTouchUp(screenPoint: CGPoint, mapPoint: AGSPoint) {
        // to override
    }

    /// Makes the map available for CommonMapViewController.
    var geoView: AGSGeoView {
        fatalError("// to override")
    }

    // MARK: - Map Funcs
    /// Identify the objcect on the map at a screen point
    ///
    /// - Parameters:
    ///    - screenPoint: the screen point point to check
    /// - Returns: result if something is found
    func identify(screenPoint: CGPoint, _ completion: @escaping (AGSIdentifyGraphicsOverlayResult?) -> Void) {
        // to override
        completion(nil)
    }

    /// Checks if a given map point has valid coordinates by ensuring neither its latitude or longitude is 0.
    ///
    /// - Parameters:
    ///    - mapPoint: the map point to check
    /// - Returns: `true` if the coordinates are valid, `false` otherwise
    public func isValidMapPoint(_ mapPoint: AGSPoint?) -> Bool {
        guard let mapPoint = mapPoint else { return false }

        let coordinate2D = mapPoint.toCLLocationCoordinate2D()
        return coordinate2D.latitude != 0 || coordinate2D.longitude != 0
    }

    deinit {
        cancellables.removeAll()
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension CommonMapViewController: AGSGeoViewTouchDelegate {
    open func geoView(_ geoView: AGSGeoView,
                      didTapAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint) {
        guard mapViewModel.keyboardIsHidden else { return }
        let correctMapPoint = AGSPoint(clLocationCoordinate2D: mapPoint.toCLLocationCoordinate2D())

        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        guard !screenPoint.isOriginPoint, isValidMapPoint(correctMapPoint) else { return }

        identify(screenPoint: screenPoint) { [weak self] in
            self?.handleCustomMapTap(mapPoint: correctMapPoint, screenPoint: screenPoint, identifyResult: $0)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard mapViewModel.keyboardIsHidden else { return }
        let correctMapPoint = AGSPoint(clLocationCoordinate2D: mapPoint.toCLLocationCoordinate2D())

        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        guard !screenPoint.isOriginPoint, isValidMapPoint(correctMapPoint) else { return }
            identify(screenPoint: screenPoint) { [weak self] in
                self?.handleCustomMapLongPress(mapPoint: correctMapPoint, identifyResult: $0)
        }
    }

    open func geoView(_ geoView: AGSGeoView,
                      didTouchDownAtScreenPoint screenPoint: CGPoint,
                      mapPoint: AGSPoint,
                      completion: @escaping (Bool) -> Void) {
        guard mapViewModel.keyboardIsHidden else { return }
        let correctMapPoint = AGSPoint(clLocationCoordinate2D: mapPoint.toCLLocationCoordinate2D())

        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        guard !screenPoint.isOriginPoint, isValidMapPoint(correctMapPoint) else { return }

        lastValidPoints = (screenPoint, correctMapPoint)
        identify(screenPoint: screenPoint) { [weak self] in
            self?.handleCustomMapTouchDown(mapPoint: correctMapPoint, identifyResult: $0, completion: completion)
        }
    }

    open func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard mapViewModel.keyboardIsHidden else { return }
        let correctMapPoint = AGSPoint(clLocationCoordinate2D: mapPoint.toCLLocationCoordinate2D())

        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        guard !screenPoint.isOriginPoint, isValidMapPoint(correctMapPoint) else { return }

        lastValidPoints = (screenPoint, correctMapPoint)
        handleCustomMapDrag(mapPoint: correctMapPoint)
    }

    open func geoView(_ geoView: AGSGeoView, didTouchUpAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard mapViewModel.keyboardIsHidden else { return }
        let correctMapPoint = AGSPoint(clLocationCoordinate2D: mapPoint.toCLLocationCoordinate2D())

        // ArgCIS has a big bug. It does not handle well a drag gesture that gets out of the bounds
        // of the ArcGIS geo view (a cancelled touch event). This causes this callback to be called
        // with a 'nil'/unitialized mapPoint. AGSPoint being a objc object it can be nil and anyway
        // be branched in Swift as a non-nil object.
        let pointsAreValid = !screenPoint.isOriginPoint && isValidMapPoint(correctMapPoint)
        let points = pointsAreValid ? (screenPoint, correctMapPoint) : lastValidPoints

        guard let screenPointToUse = points.screen, let mapPointToUse = points.map else { return }

        handleCustomMapTouchUp(screenPoint: screenPointToUse, mapPoint: mapPointToUse)
        lastValidPoints = (nil, nil)
    }

    open func geoViewDidCancelTouchDrag(_ geoView: AGSGeoView) {
        guard let screenPoint = lastValidPoints.screen, let mapPoint = lastValidPoints.map else { return }

        handleCustomMapTouchUp(screenPoint: screenPoint, mapPoint: mapPoint)
        lastValidPoints = (nil, nil)
    }
}
