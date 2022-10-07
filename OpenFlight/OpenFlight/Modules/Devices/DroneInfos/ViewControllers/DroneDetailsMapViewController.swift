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

/// Protocol used to inform view controller of the dismissal of th modal.
protocol DroneDetailsMapViewProtocol: AnyObject {
    /// Dismisses screen.
    func dismissScreen()
}

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
    @IBOutlet private weak var bellStackView: UIStackView!
    @IBOutlet private weak var bellImageView: UIImageView!
    @IBOutlet private weak var bellLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var mapController: MapViewController?
    private let viewModel = DroneDetailsMapViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Properties
    private weak var delegate: DroneDetailsMapViewProtocol?

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator, delegate: DroneDetailsMapViewProtocol) -> DroneDetailsMapViewController {

        let viewController = StoryboardScene.DroneDetailsMap.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.delegate = delegate
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        initMap()
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
        containerView?.isUserInteractionEnabled = true
        coordinateView.layer.cornerRadius = Style.largeCornerRadius
        bellStackView.layer.cornerRadius = Style.largeCornerRadius
        lastPositionTitleLabel.text = L10n.droneDetailsLastKnownPosition
    }

    /// Init map view controller.
    func initMap() {
        if mapController == nil {
            let controller = MapViewController.instantiate(mapMode: .droneDetails)
            addChild(controller)
            mapController = controller
        }
        if let mapView = mapController?.view {
            containerView.addWithConstraints(subview: mapView)
        }
        mapController?.didMove(toParent: self)
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
