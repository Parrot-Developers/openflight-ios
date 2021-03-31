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

/// Flight Plan Dashboard displays flight plan overview.
final class FlightPlanDashboardViewController: UIViewController, FileShare {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var flightplanTitle: UILabel!
    @IBOutlet private weak var flightPlanSubtitle: UILabel!
    @IBOutlet private weak var openButton: UIButton!
    @IBOutlet private weak var mapView: UIView!
    @IBOutlet private weak var durationTitleLabel: UILabel!
    @IBOutlet private weak var durationTimeLabel: UILabel!
    @IBOutlet private weak var mediaLabel: UILabel!
    @IBOutlet private weak var batteryLabel: UILabel!
    @IBOutlet private weak var contentStackView: UIStackView!

    // MARK: - Private Properties
    private var mapController: MapViewController?
    private var flightPlan: FlightPlanViewModel?
    private weak var coordinator: Coordinator?

    // MARK: - Internal Properties
    var temporaryShareUrl: URL?

    // MARK: - Setup
    /// Instantiates FlightPlanDashboardViewController.
    ///
    /// - Parameters:
    ///     - coordinator: Coordinator
    ///     - viewModel: Flight Plan view model
    /// - Returns: FlightPlanDashboardViewController instance
    static func instantiate(coordinator: Coordinator,
                            viewModel: FlightPlanViewModel) -> FlightPlanDashboardViewController {
        let viewController = StoryboardScene.FlightPlanDashboardViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.flightPlan = viewModel

        return viewController
    }

    // MARK: - Deinit
    deinit {
        cleanTemporaryFile()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        flightplanTitle.text = flightPlan?.state.value.title ?? ""
        updateContainers()
        initMap()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateCorners()
        displayFlightPlan()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let historyViewController = segue.destination as? FlightPlanHistoryViewController {
            historyViewController.flightplan = flightPlan
            historyViewController.tableType = .miniHistory
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateContainers()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension FlightPlanDashboardViewController {
    @IBAction func openFlighPlanButtonTouchUpInside(_ sender: Any) {
        (coordinator as? DashboardCoordinator)?.showFlightPlan(viewModel: flightPlan)
    }

    @IBAction func closeButtonTouchUpInside() {
        coordinator?.dismiss()
    }

    @IBAction func shareButtonTouchUpInside(_ sender: Any) {
        shareFile(data: flightPlan?.flightPlan?.asData,
                  name: flightPlan?.state.value.title,
                  fileExtension: FlightPlanConstants.jsonExtension)
    }
}

// MARK: - Private Funcs
private extension FlightPlanDashboardViewController {
    /// Init map controller.
    func initMap() {
        let controller = MapViewController.instantiate(mapMode: .flightPlan)
        controller.view.backgroundColor = .clear
        addChild(controller)
        controller.view.removeFromSuperview()
        controller.view.frame = mapView.bounds
        mapView.addSubview(controller.view)
        self.view.layoutIfNeeded()
        controller.didMove(toParent: self)
        mapController = controller
    }

    func initView() {
        bgView.backgroundColor = ColorName.black.color
        headerView.backgroundColor = .clear
        flightplanTitle.makeUp(with: .big)
        flightPlanSubtitle.makeUp(and: .white50)
        flightPlanSubtitle.text = L10n.commonFlightPlan
        openButton.applyCornerRadius(Style.largeCornerRadius)
        openButton.backgroundColor = ColorName.white12.color
        openButton.makeup(with: .large, color: ColorName.white)
        openButton.setTitle(L10n.flightPlanOpenLabel, for: .normal)
        durationTitleLabel.text = Style.dash
        durationTitleLabel.makeUp()
        durationTimeLabel.text = ""
        durationTimeLabel.makeUp(and: .black40)
        mediaLabel.text = Style.dash
        mediaLabel.makeUp()
        batteryLabel.text = Style.dash
        batteryLabel.makeUp()
        addCloseButton(onTapAction: #selector(closeButtonTouchUpInside),
                       targetView: headerView,
                       style: .cross)
    }

    /// Displays FlightPlan on the map.
    func displayFlightPlan() {
        if let flightPlan = flightPlan,
           let type = flightPlan.state.value.type {
            // 1) Deduce modeKey from type (Can be a custom Flight Plan).
            let modeKey = FlightPlanTypeManager.shared.missionModeKey(for: type)
            // 2) Set Flight Plan mission mode.
            mapController?.currentMissionProviderState?.mode = MissionsManager.shared.missionSubModeFor(key: modeKey)
            // 3) Display Flight Plan.
            mapController?.displayFlightPlan(flightPlan, shouldReloadCamera: true)
            mapController?.sceneView.isUserInteractionEnabled = false
        }
    }

    /// Update background top corners.
    func updateCorners() {
        bgView.applyCornerRadius(Style.largeCornerRadius,
                                 maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }

    /// Update containers display, regarding orientation.
    func updateContainers() {
        contentStackView.axis = UIApplication.isLandscape ? .horizontal : .vertical
        updateCorners()
    }
}
