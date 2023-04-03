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

import UIKit
import MapKit
import Combine
import ArcGIS

/// Protocol used to inform view controller of the dismissal of th modal.
protocol DroneDetailsMapViewProtocol: AnyObject {
    /// Dismisses screen.
    func dismissScreen()
}

/// Display map into drone details screen.
final class DroneDetailsMapViewController: MapWithOverlaysViewController {
    // MARK: - Outlets
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var lastPositionTitleLabel: UILabel!
    @IBOutlet private weak var lastPositionValueLabel: UILabel!
    @IBOutlet private weak var coordinateView: UIView!
    @IBOutlet private weak var coordinateButton: UIButton!
    @IBOutlet private weak var bellButton: UIButton!
    @IBOutlet private weak var bellStackView: UIStackView!
    @IBOutlet private weak var bellImageView: UIImageView!
    @IBOutlet private weak var bellLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var viewModel: DroneDetailsMapViewModel!
    private var cancellables = Set<AnyCancellable>()
    private var droneLocationOverlay: DroneLocationGraphicsOverlay?

    // MARK: - Public Properties
    private weak var delegate: DroneDetailsMapViewProtocol?

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator, delegate: DroneDetailsMapViewProtocol,
                            droneDetailsMapViewModel: DroneDetailsMapViewModel) -> DroneDetailsMapViewController {
        let viewController = StoryboardScene.DroneDetailsMap.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.delegate = delegate
        viewController.viewModel = droneDetailsMapViewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        droneLocationOverlay = addDroneOverlay(showWhenDisconnected: true)
        setupViewModel()
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

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func getCenter(completion: @escaping(AGSViewpoint?) -> Void) {
        if let coordinate = viewModel.location?.coordinate {
            completion(AGSViewpoint(center: AGSPoint(clLocationCoordinate2D: coordinate),
                                    scale: CommonMapConstants.cameraDistanceToCenterLocation))
        } else {
            completion(nil)
        }
    }
}

// MARK: - Actions
private extension DroneDetailsMapViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        self.view.backgroundColor = .clear
        coordinator?.dismiss()
        delegate?.dismissScreen()
    }

    @IBAction func bellButtonTouchedUpInside(_ sender: Any) {
        viewModel.toggleBeeper()
    }

    @IBAction func coordinateButtonTouchedUpInside(_ sender: Any) {
        if let location = viewModel.location {
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
        coordinateView.layer.cornerRadius = Style.largeCornerRadius
        bellStackView.layer.cornerRadius = Style.largeCornerRadius
        lastPositionTitleLabel.text = L10n.droneDetailsLastKnownPosition
    }

    /// Sets up the view model.
    func setupViewModel() {
        viewModel.bellButtonBgColor
            .sink { [unowned self] in
                bellStackView.backgroundColor = $0
            }
            .store(in: &cancellables)

        viewModel.bellImage
            .sink { [unowned self] in
                bellImageView.image = $0
            }
            .store(in: &cancellables)

        viewModel.bellTextColor
            .sink { [unowned self] in
                bellLabel.textColor = $0
                bellImageView.tintColor = $0
            }
            .store(in: &cancellables)

        viewModel.bellText
            .sink { [unowned self] in
                bellLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.isBellButtonEnabled
            .sink { [unowned self] in
                bellButton.isUserInteractionEnabled = $0
                bellStackView.alphaWithEnabledState($0)
            }
            .store(in: &cancellables)

        viewModel.coordinateButtonTitle
            .sink { [unowned self] in
                guard let title = $0 else {
                    coordinateView.isHidden = true
                    return
                }
                coordinateView.isHidden = false
                coordinateButton.setTitle(title, for: .normal)
            }
            .store(in: &cancellables)

        viewModel.subTitle
            .sink { [unowned self] in
                lastPositionValueLabel.text = $0
            }
            .store(in: &cancellables)
    }
}
