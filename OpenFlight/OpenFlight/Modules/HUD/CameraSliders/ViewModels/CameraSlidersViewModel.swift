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

import Foundation
import Combine
import GroundSdk

/// View model for camera sliders view
class CameraSlidersViewModel {

    // MARK: - Private properties
    private var zoomSliderTimer: Timer?
    private var gimbalSliderTimer: Timer?
    private var showInfoTiltLabelTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var bottomBarModeObserver: Any?
    private var splitModeObserver: Any?
    private unowned var joysticksAvailabilityService: JoysticksAvailabilityService
    private unowned var zoomService: ZoomService
    private unowned var tiltService: GimbalTiltService
    @Published private var bottomBarOpened = false

    // MARK: - Internal properties

    // Info tilt
    @Published private(set) var showInfoTiltLabelFlag = false
    private(set) var constraintInfoLabelUpdated = false

    // Joystick
    @Published private(set) var showJoysticksButton = false
    @Published private(set) var joysticksButtonImage = Asset.Joysticks.icJogsHide.image

    // Zoom
    @Published private(set) var showZoomSlider = false {
        didSet {
            if showZoomSlider {
                scheduleZoomSliderHiding()
            }
        }
    }
    @Published private(set) var zoomButtonTitle = "N/A"
    @Published private(set) var zoomButtonColor = ColorName.defaultIconColor.color
    var zoomButtonEnabled: AnyPublisher<Bool, Never> {
        zoomService.maxZoomPublisher
            .map { [unowned self] in $0 <= zoomService.minZoom }
            .combineLatest(zoomService.isZoomAvailablePublisher)
            .map { (unitaryRange, available) in available && !unitaryRange }
            .eraseToAnyPublisher()
    }
    var zoomButtonHidden: AnyPublisher<Bool, Never> { $showZoomSlider.eraseToAnyPublisher() }
    var overzoomingEvent: AnyPublisher<Bool, Never> { zoomService.overzoomingEventPublisher }

    // Gimbal tilt
    @Published private(set) var showGimbalTiltSlider = false {
        didSet {
            if showGimbalTiltSlider {
                scheduleGimbalSliderHiding()
            }
        }
    }
    var overtiltEvent: AnyPublisher<Bool, Never> { tiltService.overTiltEventPublisher }
    var undertiltEvent: AnyPublisher<Bool, Never> { tiltService.underTiltEventPublisher }
    var gimbalTiltValue: AnyPublisher<Double, Never> { tiltService.currentTiltPublisher }
    var gimbalTiltButtonHidden: AnyPublisher<Bool, Never> { $showGimbalTiltSlider.eraseToAnyPublisher() }
    var gimbalTiltButtonEnabled: AnyPublisher<Bool, Never> {
        tiltService.tiltIsAvailablePublisher
            .combineLatest(tiltService.tiltRangePublisher)
            .map { (available, range) in available && range.upperBound > range.lowerBound }
            .eraseToAnyPublisher()
    }

    /// Init
    /// - Parameters:
    ///     - joysticksAvailabilityService: the joysticks availability service
    ///     - zoomService: the zoom service
    ///     - tiltService: the gimbal tilt service
    init(joysticksAvailabilityService: JoysticksAvailabilityService,
         zoomService: ZoomService,
         tiltService: GimbalTiltService) {
        self.joysticksAvailabilityService = joysticksAvailabilityService
        self.zoomService = zoomService
        self.tiltService = tiltService
        listenBottomBarModeChanges()
        listenJoysticks()
        listenSplitModeChanges()
        listenZoom()
    }

    deinit {
        NotificationCenter.default.remove(observer: splitModeObserver)
    }
}

// MARK: - Private functions
private extension CameraSlidersViewModel {

    /// Invalidate previous scheduled zoom slider hiding if any and schedule it
    func scheduleZoomSliderHiding() {
        zoomSliderTimer?.invalidate()
        zoomSliderTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] _ in
            self?.showZoomSlider = false
        })
    }

    /// Listen to joysticks related publishers
    func listenJoysticks() {
        joysticksAvailabilityService.joysticksAvailablePublisher
            .combineLatest($bottomBarOpened)
            .sink { [unowned self] (joysticksAvailables, bottomBarOpened) in
                showJoysticksButton = joysticksAvailables && !bottomBarOpened
            }
            .store(in: &cancellables)
        joysticksAvailabilityService.showJoysticksPublisher
            .sink { [unowned self] in
                joysticksButtonImage = $0 ? Asset.Joysticks.icJogsHide.image : Asset.Joysticks.icJogsShow.image
            }
            .store(in: &cancellables)
    }

    /// Listen to zoom publisher
    func listenZoom() {
        zoomService.currentZoomPublisher
            .combineLatest(zoomService.maxLosslessZoomPublisher)
            .sink { [unowned self] (currentZoom, maxLosslessZoom) in
                zoomButtonTitle = String(format: "%.01f", currentZoom) + Style.multiplySign
                zoomButtonColor = UIColor(named: currentZoom > maxLosslessZoom ? .orangePeel : ColorName.defaultIconColor)
            }
            .store(in: &cancellables)
    }

    /// Listen for bottom bar changes
    func listenBottomBarModeChanges() {
        // TODO: seems like missing UI service
        bottomBarModeObserver = NotificationCenter.default.addObserver(forName: .bottomBarModeDidChange,
                                                                       object: nil,
                                                                       queue: nil) { [weak self] notification in
            guard let bottomBarMode = notification.userInfo?[BottomBarMode.notificationKey] as? BottomBarMode else { return }
            self?.bottomBarOpened = bottomBarMode != .closed
        }
    }

    /// Listen for split mode changes
    func listenSplitModeChanges() {
        // TODO: seems like missing UI service
        splitModeObserver = NotificationCenter.default.addObserver(forName: .splitModeDidChange,
                                                                   object: nil,
                                                                   queue: nil) { [unowned self] notification in
            if let splitMode = notification.userInfo?[SplitControlsConstants.splitScreenModeKey] as? SplitScreenMode {
                showZoomSlider = splitMode != .secondary
            }
        }
    }
}

// MARK: - Actions
extension CameraSlidersViewModel {

    func joysticksButtonTapped() {
        joysticksAvailabilityService.setJoysticksVisibility(!joysticksAvailabilityService.showJoysticks)
    }

    func zoomButtonTapped() {
        zoomSliderTimer?.invalidate()
        showZoomSlider = !showZoomSlider
    }

    func tiltButtonTapped() {
        gimbalSliderTimer?.invalidate()
        showGimbalTiltSlider = !showGimbalTiltSlider
    }

    func keepZoomSliderOpenedForATime() {
        scheduleZoomSliderHiding()
    }

    func keepGimbalTiltSliderOpened() {
        gimbalSliderTimer?.invalidate()
    }

    func hideGimbalTiltSlider() {
        gimbalSliderTimer?.invalidate()
        showGimbalTiltSlider = false
    }

    func hideZoomSlider() {
        gimbalSliderTimer?.invalidate()
        showZoomSlider = false
    }

    func scheduleGimbalSliderHiding() {
        gimbalSliderTimer?.invalidate()
        gimbalSliderTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] _ in
            self?.showGimbalTiltSlider = false
        })
    }

    func showInfoTiltLabel() {
        // cancel `hideInfoTiltLabel` while tilt value is changing
        showInfoTiltLabelTimer?.invalidate()
        // show info label when the value from gimbal is changing
        showInfoTiltLabelFlag = true
        // active a timer to close the infoTiltLabel in 2 sec
        showInfoTiltLabelTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {[weak self] _ in
            self?.showInfoTiltLabelFlag = false
            self?.resetConstraintInfoTiltLabel()
        }
    }

    func updateConstraintInfoTiltLabel() {
        constraintInfoLabelUpdated = true
    }

    func resetConstraintInfoTiltLabel() {
        constraintInfoLabelUpdated = false
    }
}
