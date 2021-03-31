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

// MARK: - Public Enums
/// Stores different type of history table view.
public enum HistoryTableType {
    /// Table view is in a mini display mode.
    case miniHistory
    /// Table view is in a full display mode.
    case fullHistory
}

// MARK: - Protocols
protocol FlightPlanHistoryDelegate: class {
    /// Called when user taps the medias view in a selected cell.
    ///
    /// - Parameters:
    ///     - fpExecution: the current flight plan execution
    ///     - action: action to perform
    func didTapOnMedia(fpExecution: FlightPlanExecution,
                       action: HistoryMediasActionType?)
}

/// FlightPlan History View Controller.
final class FlightPlanHistoryViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Internal Properties
    weak var delegate: FlightPlanHistoryDelegate?
    weak var coordinator: Coordinator?

    /// Defines the type of the flight plan history table view.
    var tableType: HistoryTableType = .fullHistory {
        didSet {
            fpExecutionsViews = FlightPlanHistorySyncManager.shared.syncProvider?.historySyncViews(type: tableType,
                                                                                                   flightPlanViewModel: flightplan) ?? [:]
        }
    }
    /// Return current flight plan view model.
    var flightplan: FlightPlanViewModel? {
        didSet {
            data = flightplan?.executions ?? []
        }
    }
    /// List of history views for each flight plan execution.
    var fpExecutionsViews: [String: HistoryMediasView] = [:]

    // MARK: - Private Properties
    private var data: [FlightPlanExecution] = []

    // MARK: - Private Enums
    private enum Constants {
        static let cellSeparatorHorizontalInset: CGFloat = 16.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension FlightPlanHistoryViewController {
    /// Init view.
    func initView() {
        view.backgroundColor = .clear
        headerLabel.makeUp(and: .white50)
        tableView.register(cellType: FlightPlanHistoryTableViewCell.self)
        if tableType == .miniHistory {
            tableView.applyCornerRadius(Style.largeCornerRadius)
        }
        tableView.makeUp(backgroundColor: .clear)
        tableView.dataSource = self

        let dataCount = data.count
        headerLabel.text = dataCount > 1 ? L10n.flightPlanExecutionPlural(dataCount) : L10n.flightPlanExecutionSingular(dataCount)
    }
}

// MARK: - UITableViewDataSource
extension FlightPlanHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath,
                                                 cellType: FlightPlanHistoryTableViewCell.self)
        cell.setup(fpExecution: data[indexPath.row],
                   mediasView: fpExecutionsViews[data[indexPath.row].executionId],
                   tableType: tableType)
        cell.delegate = self

        if tableType == .miniHistory,
           indexPath.row == data.count - 1 {
            // Hide last cell separator.
            cell.separatorInset.right = self.view.frame.width
            cell.separatorInset.left = 0.0
        } else {
            // Show cell separator in other cases.
            cell.separatorInset.right = Constants.cellSeparatorHorizontalInset
            cell.separatorInset.left = Constants.cellSeparatorHorizontalInset
        }
        if tableType != .miniHistory {
            cell.backgroundColor = .clear
        }

        return cell
    }
}

// MARK: - FlightPlanHistoryCellDelegate
extension FlightPlanHistoryViewController: FlightPlanHistoryCellDelegate {
    func didTapOnResume(fpExecution: FlightPlanExecution) {
        let canResume = flightplan?.resumeExecution(fpExecution) ?? false
        if canResume {
            coordinator?.dismiss()
        }
    }

    func didTapOnMedia(fpExecution: FlightPlanExecution, action: HistoryMediasActionType?) {
        delegate?.didTapOnMedia(fpExecution: fpExecution,
                                action: action)
    }
}
