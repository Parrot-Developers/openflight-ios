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

protocol HistoryMediasAction {
    /// Manages touch on history cell.
    ///
    /// - Parameters:
    ///     - flightModel: current flight plan model
    ///     - actionType: type of the action for the selected flight plan execution
    func handleHistoryCellAction(with flightModel: FlightPlanModel,
                                 actionType: HistoryMediasActionType)
}

final class FlightPlanFullHistoryViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var headerView: UIView!
    @IBOutlet private weak var flightplanTitle: UILabel!
    @IBOutlet private weak var flightPlanSubtitle: UILabel!

    // MARK: - Private Properties
    private var projectModel: ProjectModel?
    private var flightPlanTitle: String?
    private weak var coordinator: Coordinator?

    // MARK: - Setup
    /// Instantiates FlightPlanFullHistoryViewController.
    ///
    /// - Parameters:
    ///     - coordinator: Coordinator
    ///     - projectModel: Flight Plan project model
    ///     - title: title of the last flight plan
    /// - Returns: FlightPlanFullHistoryViewController instance.
    static func instantiate(coordinator: Coordinator,
                            projectModel: ProjectModel?,
                            flightPlanTitle: String) -> FlightPlanFullHistoryViewController {
        let viewController = StoryboardScene.FlightPlanDashboardViewController
            .flightPlanFullHistoryViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.projectModel = projectModel
        viewController.flightPlanTitle = flightPlanTitle

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateCorners()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let historyViewController = segue.destination as? FlightPlanHistoryViewController {
            historyViewController.project = projectModel
            historyViewController.tableType = .fullHistory
            historyViewController.coordinator = coordinator
            historyViewController.delegate = self
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension FlightPlanFullHistoryViewController {
    @IBAction func closeButtonTouchUpInside() {
        coordinator?.dismiss()
    }
}

// MARK: - Private Funcs
private extension FlightPlanFullHistoryViewController {
    /// Init view.
    func initView() {
        flightplanTitle.text = flightPlanTitle
        bgView.backgroundColor = ColorName.black.color
        headerView.backgroundColor = .clear
        flightplanTitle.makeUp(with: .big)
        flightPlanSubtitle.makeUp(and: .white50)
        flightPlanSubtitle.text = L10n.flightPlanHistory
        addCloseButton(onTapAction: #selector(closeButtonTouchUpInside),
                       targetView: headerView,
                       style: .cross)
    }

    /// Update background top corners.
    func updateCorners() {
        bgView.applyCornerRadius(Style.largeCornerRadius,
                                 maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
    }
}

// MARK: - FlightPlanHistoryDelegate
extension FlightPlanFullHistoryViewController: FlightPlanHistoryDelegate {
    func didTapOnMedia(flightModel: FlightPlanModel, action: HistoryMediasActionType?) {
        guard let strongAction = action else { return }

        (coordinator as? HistoryMediasAction)?.handleHistoryCellAction(with: flightModel,
                                                                       actionType: strongAction)
    }
}
