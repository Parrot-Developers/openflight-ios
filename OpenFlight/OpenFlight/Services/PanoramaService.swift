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

import Combine
import GroundSdk
import SwiftyUserDefaults

private extension ULogTag {
    static let tag = ULogTag(name: "Panorama")
}

/// Panorama service.
public protocol PanoramaService: AnyObject {
    /// Publisher telling whether current camera capture mode is a panorama mode.
    var panoramaModeActivePublisher: AnyPublisher<Bool, Never> { get }

    /// Whether current camera capture mode is a panorama mode.
    var panoramaModeActiveValue: Bool { get set }

    /// Whether a panorama is ongoing.
    var panoramaOngoing: Bool { get }

    /// Publisher for ongoing panorama.
    var panoramaOngoingPublisher: AnyPublisher<Bool, Never> { get }

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    /// Publisher for panorama alerts.
    var alertsPublisher: AnyPublisher<[HUDAlertType], Never> { get }

    /// Starts a panorama photo capture.
    ///
    /// - Parameters:
    ///    - mode: panorama mode
    func startPanorama(mode: PanoramaMode)

    /// Stops ongoing panorama photo capture, if any.
    func cancelPanorama()
}

/// Implementation of `PanoramaService`.
public class PanoramaServiceImpl {

    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove constants.
    // MARK: - Private Enums
    private enum Constants {
        /// Panorama alerts reset delay in seconds.
        static let alertsResetDelay = 3
    }

    // MARK: Private properties
    /// Current drone holder service.
    private unowned let currentDroneHolder: CurrentDroneHolder
    /// The banner alert manager service.
    private let bamService: BannerAlertManagerService
    /// Whether current camera capture mode is a panorama mode.
    private var panoramaModeActiveSubject = CurrentValueSubject<Bool, Never>(false)
    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    /// Panorama alerts subject.
    private var alertsSubject = PassthroughSubject<[HUDAlertType], Never>()
    /// Ongoing panorama subject.
    private var panoramaOngoingSubject = CurrentValueSubject<Bool, Never>(false)
    // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
    // TODO: Remove property.
    /// Alerts reset task.
    private var alertsReset: AnyCancellable?
    /// Reference to drone flying indicators instrument.
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    /// Reference to animation piloting interface.
    private var animationPilotingItfRef: Ref<AnimationPilotingItf>?
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: current drone holder service
    ///   - bamService: the banner alert manager service
    init(currentDroneHolder: CurrentDroneHolder,
         bamService: BannerAlertManagerService) {
        self.currentDroneHolder = currentDroneHolder
        self.bamService = bamService

        // listen to drone changes
        listen(dronePublisher: currentDroneHolder.dronePublisher)
    }
}

// MARK: PanoramaService protocol conformance
extension PanoramaServiceImpl: PanoramaService {

    public var alertsPublisher: AnyPublisher<[HUDAlertType], Never> {
        alertsSubject.eraseToAnyPublisher()
    }

    public var panoramaModeActivePublisher: AnyPublisher<Bool, Never> {
        panoramaModeActiveSubject.eraseToAnyPublisher()
    }

    public var panoramaOngoingPublisher: AnyPublisher<Bool, Never> {
        panoramaOngoingSubject.eraseToAnyPublisher()
    }

    public var panoramaModeActiveValue: Bool {
        get {
            Defaults.isPanoramaModeActivated
        }
        set {
            ULog.i(.tag, "Panorama mode active \(newValue)")
            Defaults.isPanoramaModeActivated = newValue
            panoramaModeActiveSubject.value = newValue
        }
    }

    public var panoramaOngoing: Bool {
        guard let animationItf = currentDroneHolder.drone.getPilotingItf(PilotingItfs.animation),
              let animation = animationItf.animation else {
                  return false
              }
        switch animation.type {
        case .horizontalPanorama,
                .sphericalPhotoPanorama,
                .vertical180PhotoPanorama,
                .horizontal180PhotoPanorama,
                .superWidePhotoPanorama:
            return true
        default:
            return false
        }
    }

    public func startPanorama(mode: PanoramaMode) {
        guard let animationItf = currentDroneHolder.drone.getPilotingItf(PilotingItfs.animation) else {
            ULog.i(.tag, "Cannot start panorama: piloting interface not available")
            return
        }

        // check preconditions for panorama animation
        if mode.requireDroneFlying,
           !currentDroneHolder.drone.isStateFlying {
            ULog.i(.tag, "Cannot start panorama: drone not flying")
            bamService.show(AdviceBannerAlert.takeOff)

            alertsReset?.cancel()
            // notify take off required alert
            alertsSubject.send([HUDBannerAdviceslertType.takeOff])
            // reset alert after a delay
            alertsReset = Just(true)
                .delay(for: .seconds(Constants.alertsResetDelay), scheduler: DispatchQueue.main)
                .sink { [unowned self] _ in
                    alertsSubject.send([])
                }
            // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
            // TODO: Remove code.
        } else {
            ULog.i(.tag, "Start panorama \(mode.rawValue)")
            // start panorama animation
            _ = animationItf.startAnimation(config: mode.animationConfig)
        }
    }

    public func cancelPanorama() {
        guard let animationItf = currentDroneHolder.drone.getPilotingItf(PilotingItfs.animation),
              panoramaOngoing else {
                  return
              }
        ULog.i(.tag, "Cancel panorama")
        _ = animationItf.abortCurrentAnimation()
    }
}

// MARK: Private functions
private extension PanoramaServiceImpl {

    /// Listens for the current drone.
    ///
    /// - Parameter dronePublisher: the drone publisher
    func listen(dronePublisher: AnyPublisher<Drone, Never>) {
        dronePublisher.sink { [unowned self] drone in
            listenFlyingIndicators(drone: drone)
            listenAnimationPilotingItf(drone: drone)
        }
        .store(in: &cancellables)
    }

    /// Listens flying indicators instrument.
    ///
    /// - Parameter drone: the current drone
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [unowned self] flyingIndicators in
            if flyingIndicators?.state == .flying {
                bamService.hide(AdviceBannerAlert.takeOff)
                // [Banner Alerts] Legacy code is temporarily kept for validation purpose only.
                // TODO: Remove code.
                // reset take off required alert
                alertsSubject.send([])
            }
        }
    }

    /// Listens to animation piloting interface.
    ///
    /// - Parameter drone: the current drone
    func listenAnimationPilotingItf(drone: Drone) {
        animationPilotingItfRef = drone.getPilotingItf(PilotingItfs.animation) { [weak self] animationItf in
            guard let self = self else { return }
            self.panoramaOngoingSubject.value = animationItf?.animation?.status != nil
        }
    }
}
