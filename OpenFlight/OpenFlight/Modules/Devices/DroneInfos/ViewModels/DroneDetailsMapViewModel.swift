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

import GroundSdk
import CoreLocation
import Combine

/// View Model for map which is displayed in the drone details screen.
final class DroneDetailsMapViewModel {
    // MARK: - Internal Properties
    /// Current drone location.
    @Published private(set) var location: CLLocation?
    /// Tells if beeper is playing.
    @Published private(set) var beeperIsPlaying: Bool = false
    /// Tells if drone is connected.
    @Published private(set) var droneIsConnected: Bool = false

    // MARK: - Private Properties
    private var currentDroneHolder = Services.hub.currentDroneHolder
    private var cancellables = Set<AnyCancellable>()
    private var connectionStateRef: Ref<DeviceState>?
    private var gpsRef: Ref<Gps>?
    private var beeperRef: Ref<Beeper>?

    // MARK: - Init
    init() {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                listenGps(drone)
                listenBeeper(drone)
                listenConnectionState(drone)
            }
            .store(in: &cancellables)
    }

    /// Toggles drone beeper.
    func toggleBeeper() {
        if beeperIsPlaying {
            _ = beeperRef?.value?.stopAlertSound()
        } else {
            _ = beeperRef?.value?.startAlertSound()
        }
    }

    /// Publishes the bell background color.
    var bellButtonBgColor: AnyPublisher<UIColor, Never> {
        $beeperIsPlaying
            .map {
                return $0 ? ColorName.whiteAlbescent.color : ColorName.highlightColor.color
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the bell background color.
    var bellImage: AnyPublisher<UIImage, Never> {
        $beeperIsPlaying
            .map {
                return $0 ? Asset.Drone.icBellOn.image : Asset.Drone.icBellOff.image
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the bell text and tint color.
    var bellTextColor: AnyPublisher<UIColor, Never> {
        $beeperIsPlaying
            .map {
                return $0 ? ColorName.defaultTextColor.color : .white
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the bell text.
    var bellText: AnyPublisher<String, Never> {
        $beeperIsPlaying
            .map {
                return $0 ? L10n.droneDetailsStopRinging : L10n.droneDetailsRingTheDrone
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the enabled state of the bell button.
    var isBellButtonEnabled: AnyPublisher<Bool, Never> {
        $droneIsConnected
            .map { return $0 }
            .eraseToAnyPublisher()
    }

    /// Publishes the bell button title.
    var coordinateButtonTitle: AnyPublisher<String?, Never> {
        $location
            .map {
                return $0?.coordinate.convertToDmsCoordinate()
            }
            .eraseToAnyPublisher()
    }

    /// Publishes the bell button title.
    var subTitle: AnyPublisher<String, Never> {
        $location
            .map {
                guard let location = $0 else {
                    return Style.dash
                }
                return location.timestamp.formattedString(dateStyle: .short, timeStyle: .medium)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsMapViewModel {
    /// Starts watcher for drone's connection state.
    ///
    /// - Parameter drone: the current drone
    func listenConnectionState(_ drone: Drone) {
        connectionStateRef = drone.getState { [weak self] state in
            self?.droneIsConnected = state?.connectionState == .connected
        }
    }

    /// Starts watcher for drone gps.
    ///
    /// - Parameter drone: the current drone
    func listenGps(_ drone: Drone) {
        gpsRef = drone.getInstrument(Instruments.gps) { [weak self] gps in
            self?.location = gps?.lastKnownLocation
        }
    }

    /// Starts watcher for drone beeper.
    ///
    /// - Parameter drone: the current drone
    func listenBeeper(_ drone: Drone) {
        beeperRef = drone.getPeripheral(Peripherals.beeper) { [weak self] beeper in
            self?.beeperIsPlaying = beeper?.alertSoundPlaying == true
        }
    }
}
