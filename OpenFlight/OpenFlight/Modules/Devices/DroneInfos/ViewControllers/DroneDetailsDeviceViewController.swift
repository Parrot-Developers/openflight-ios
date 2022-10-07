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

import UIKit
import Combine

/// Displays drone specific details about device state.
final class DroneDetailsDeviceViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var componentsStatusView: DroneComponentsStatusView!
    @IBOutlet private weak var nbSatelliteLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var gpsImageView: UIImageView!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var satelliteImageView: UIImageView!
    @IBOutlet private weak var networkImageView: UIImageView!

    // MARK: - Private Properties
    private let droneInfoViewModel = DroneInfosViewModel()
    private var cancellables = Set<AnyCancellable>()

    private weak var coordinator: Coordinator?

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> DroneDetailsDeviceViewController {
        let viewController = StoryboardScene.DroneDetailsDevice.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindToViewModel()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension DroneDetailsDeviceViewController {
    func setupUI() {
        batteryLabel.makeUp(with: .current, color: .defaultTextColor)
        nbSatelliteLabel.makeUp(with: .current, color: .defaultTextColor)
    }

    /// Binds the UI element to their counterpart in the view model
    ///
    /// If a value is updated in the view model the UI will be updated too automaticaly
    func bindToViewModel() {
        bindBattery()
        bindGpsStrength()
        bindDroneName()
        bindCellularStrength()
        bindGimbalErrorImage()
        bindFrontStereoGimbalErrorImage()
        bindStereoVisionStatus()
        bindCopterMotorsErrors()
        bindConnectionState()
        bindSatelliteCount()
    }
}

private extension DroneDetailsDeviceViewController {

    /// Binds the view model and the battery label
    func bindBattery() {
        droneInfoViewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                batteryLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryLevel.currentValue)
                batteryImageView.image = batteryLevel.batteryImage
            }
            .store(in: &cancellables)
    }

    /// Binds the view model and the gps image view
    func bindGpsStrength() {
        droneInfoViewModel.$gpsStrength
            .sink { [unowned self] gpsStrength in
                gpsImageView.image = gpsStrength.image
            }
            .store(in: &cancellables)
    }

    /// Binds the drone's name from the view model to the nameLabel
    func bindDroneName() {
        droneInfoViewModel.$droneName
            .sink { [unowned self] name in
                if let parent = self.parent as? DroneDetailsViewController {
                    parent.nameLabel.text = name
                    parent.nameLabel.isHidden = name.isEmpty
                }
            }
            .store(in: &cancellables)
    }

    /// Binds the cellular strength from the view model to networkImageView
    func bindCellularStrength() {
        droneInfoViewModel.$cellularStrength
            .sink { [unowned self] cellularStrength in
                networkImageView.image = cellularStrength.signalIcon
            }
            .store(in: &cancellables)
    }

    /// Binds the gimbal error image from the view model to the componentStatusView model
    func bindGimbalErrorImage() {
        droneInfoViewModel.$gimbalErrorImage
            .sink { [unowned self] errorImage in
                componentsStatusView.model.gimbalErrorImage = errorImage
            }
            .store(in: &cancellables)
    }

    /// Binds the front stereo gimbal error image from the view model to the componentStatusView model
    func bindFrontStereoGimbalErrorImage() {
        droneInfoViewModel.$frontStereoGimbalErrorImage
            .sink { [unowned self] errorImage in
                componentsStatusView.model.frontStereoGimbalErrorImage = errorImage
            }
            .store(in: &cancellables)
    }

    /// Binds the stereo vision status from the view model to the componentStatusView model
    func bindStereoVisionStatus() {
        droneInfoViewModel.$stereoVisionStatus
            .sink { [unowned self] stereoVisionStatus in
                componentsStatusView.model.stereoVisionStatus = stereoVisionStatus
            }
            .store(in: &cancellables)
    }

    /// Binds the copter's motor errors from the view model to the componentStatusView model
    func bindCopterMotorsErrors() {
        droneInfoViewModel.$copterMotorsErrors
            .sink { [unowned self] copterMotorsErrors in
                componentsStatusView.model.update(with: copterMotorsErrors)
            }
            .store(in: &cancellables)
    }

    /// Binds the connection state from the view model to componentStatusView
    func bindConnectionState() {
        droneInfoViewModel.$connectionState
            .sink { [unowned self] connectionState in
                componentsStatusView.model.isDroneConnected = connectionState == .connected ? true : false
            }
            .store(in: &cancellables)
    }

    /// Binds the sattelite count from the view model to satellite label and image
    func bindSatelliteCount() {
        droneInfoViewModel.$satelliteCount
            .sink { [unowned self] satelliteCount in
                let isConnected = droneInfoViewModel.connectionState == .connected
                nbSatelliteLabel.text = ": " + (isConnected ? String(satelliteCount ?? 0) : Style.dash)
                satelliteImageView.tintColor = ColorName.defaultTextColor.color
            }
            .store(in: &cancellables)
    }
}
