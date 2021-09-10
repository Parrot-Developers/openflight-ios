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
    private var projectModel: ProjectModel?
    private weak var coordinator: Coordinator?

    // MARK: - Internal Properties
    var temporaryShareUrl: URL?

    // MARK: - Setup
    /// Instantiates FlightPlanDashboardViewController.
    ///
    /// - Parameters:
    ///     - coordinator: Coordinator
    ///     - projectModel: Flight Plan project model
    /// - Returns: FlightPlanDashboardViewController instance
    static func instantiate(coordinator: Coordinator,
                            projectModel: ProjectModel) -> FlightPlanDashboardViewController {
        let viewController = StoryboardScene.FlightPlanDashboardViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.projectModel = projectModel

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
        flightplanTitle.text = projectModel?.title ?? ""
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
            historyViewController.project = projectModel
            if let project = projectModel {
                historyViewController.data = Services.hub.flightPlan.projectManager.executedFlightPlans(for: project)
            } else {
                historyViewController.data = []
            }
            historyViewController.tableType = .miniHistory
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
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
//        (coordinator as? DashboardCoordinator)?.showFlightPlan(projectModel: projectModel)
    }

    @IBAction func closeButtonTouchUpInside() {
        coordinator?.dismiss()
    }

    @IBAction func shareButtonTouchUpInside(_ sender: Any) {
        guard let project = projectModel else { return }
        let data = Services.hub.flightPlan.projectManager.lastFlightPlan(for: project)?.dataSetting?.asData
        shareFile(data: data,
                  name: projectModel?.title,
                  fileExtension: "json")
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
        // Clean potential previous FP.
        controller.flightPlan = nil
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
        openButton.makeup(with: .large)
        openButton.setTitle(L10n.flightPlanOpenLabel, for: .normal)
        var lastFlightPlan: FlightPlanModel?
        if let project = projectModel {
            lastFlightPlan = Services.hub.flightPlan.projectManager.lastFlightPlan(for: project)
        }
        if let duration = lastFlightPlan?.dataSetting?.estimations.formattedDuration {
            durationTitleLabel.text = duration
        } else {
            durationTitleLabel.text = Style.dash
        }
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
        // FIXME: Do not allow share for the moment...
        shareButton.isHidden = true
    }

    /// Displays FlightPlan on the map.
    func displayFlightPlan() {
        if let projectModel = projectModel,
           let flightplan = Services.hub.flightPlan.projectManager.lastFlightPlan(for: projectModel) {
            // 1) Set Flight Plan mission mode.
            mapController?.currentMissionProviderState?.mode = Services.hub.flightPlan.typeStore.typeForKey(flightplan.type)?.missionMode
            // 2) Display Flight Plan.
            mapController?.displayFlightPlan(flightplan, shouldReloadCamera: true)
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
