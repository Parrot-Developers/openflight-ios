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

import UIKit
import MapKit

/// Display map into drone details screen.
final class DroneDetailsMapViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var lastPositionTitleLabel: UILabel!
    @IBOutlet private weak var lastPositionValueLabel: UILabel!
    @IBOutlet private weak var coordinateView: UIView!
    @IBOutlet private weak var coordinateButton: UIButton!
    @IBOutlet private weak var bellButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var mapController: MapViewController?
    private let viewModel = DroneDetailsMapViewModel()

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> DroneDetailsMapViewController {
        let viewController = StoryboardScene.DroneDetailsMap.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initMap()
        observeDatas()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.shortAnimationDuration,
                       delay: Style.shortAnimationDuration,
                       animations: {
                            self.view.backgroundColor = ColorName.nightRider80.color
                       })
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsMapViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
    }

    @IBAction func bellButtonTouchedUpInside(_ sender: Any) {
        viewModel.startOrStopBeeper()
    }

    @IBAction func coordinateButtonTouchedUpInside(_ sender: Any) {
        if let location = viewModel.state.value.location {
            let placemark = MKPlacemark(coordinate: location.coordinate, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.openInMaps()
        }
    }
}

// MARK: - Private Funcs
private extension DroneDetailsMapViewController {
    /// Init view.
    func initView() {
        mainView.customCornered(corners: [.topLeft, .topRight],
                                radius: Style.largeCornerRadius)
        containerView?.isUserInteractionEnabled = false
        coordinateView.customCornered(corners: [.allCorners],
                                      radius: Style.largeCornerRadius)
        lastPositionTitleLabel.text = L10n.droneDetailsLastKnownPosition
    }

    /// Init map view controller.
    func initMap() {
        let controller = MapViewController.instantiate(mapMode: .droneDetails)
        addChild(controller)
        mapController = controller
        if let mapView = mapController?.view {
            containerView.addWithConstraints(subview: mapView)
        }
        mapController?.didMove(toParent: self)
    }

    /// Observes data from the view model.
    func observeDatas() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateView(state)
        }
        updateView(viewModel.state.value)
    }

    /// Update the view.
    ///
    /// - Parameters:
    ///     - state: drone map state
    func updateView(_ state: DroneDetailsMapState) {
        let bellImage = state.beeperIsPlaying == true ? Asset.Drone.icBellOn.image : Asset.Drone.icBellOff.image
        bellButton.setImage(bellImage, for: .normal)

        if let location = state.location {
            coordinateButton.setTitle(location.coordinate.convertToDmsCoordinate(),
                                      for: .normal)
            lastPositionValueLabel.text = location.timestamp.formattedString(dateStyle: .short, timeStyle: .medium)
        }

        let shouldHide: Bool = state.location == nil
        coordinateView.isHidden = shouldHide
        lastPositionTitleLabel.isHidden = shouldHide
        lastPositionValueLabel.isHidden = shouldHide

        // Hide bell button when drone is disconnected.
        bellButton.isHidden = !state.isConnected()
    }
}
