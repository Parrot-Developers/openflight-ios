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

// MARK: - Internal Enums
/// Describes FlightPlansList ViewController display mode.
enum FlightPlansListDisplayMode {
    /// Full screen.
    case full
    /// Part of a sub view controller.
    case compact
}

// MARK: - Protocols
protocol FlightPlansListViewControllerDelegate: class {
    /// Called when user selects a Flight Plan.
    func didSelect(flightPlan: FlightPlanViewModel)
}

/// Manages a flight plan list.
final class FlightPlansListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyFlightPlansTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightPlansDescriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!

    // MARK: - Internal Properties
    weak var delegate: FlightPlansListViewControllerDelegate?
    var displayMode: FlightPlansListDisplayMode = .full
    var selectedFlightPlanUuid: String? {
        didSet {
            collectionView?.reloadData()
        }
    }

    // MARK: - Private Properties
    private let missionProviderViewModel: MissionProviderViewModel = MissionProviderViewModel()
    private var flightPlansListViewModel: FlightPlansListViewModel?
    private weak var coordinator: Coordinator?
    private var allFlightPlans: [FlightPlanViewModel] = [FlightPlanViewModel]() {
        didSet {
            self.collectionView.reloadData()
            self.emptyLabelStack.isHidden = !allFlightPlans.isEmpty
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscape: CGFloat = 3.0
        static let nbColumnsPortrait: CGFloat = 2.0
        static let itemSpacing: CGFloat = 10.0
        static let cellWidthRatio: CGFloat = 0.9
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        flightPlansListViewModel = FlightPlansListViewModel(delegate: self)
        collectionView.register(cellType: FlightPlanCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        emptyFlightPlansTitleLabel.text = L10n.flightPlanEmptyListTitle
        emptyFlightPlansDescriptionLabel.text = L10n.flightPlanEmptyListDesc

        // Load stored Flight Plans.
        updateDataSource()

        FlightPlanManager.shared.syncFlightPlansWithFiles(persistedFlightPlans: self.allFlightPlans) { [weak self] _ in
            self?.updateDataSource()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.collectionView.reloadData()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightPlanList,
                             logType: .screen)
    }

    /// Update display when orientation changed.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // Reload data source.
        collectionView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Privates Funcs
private extension FlightPlansListViewController {
    /// Update data source.
    func updateDataSource() {
        var predicate: NSPredicate?
        if displayMode == .compact {
            // Filter flight plan in compact mode only.
            predicate = missionProviderViewModel.state.value.mode?.flightPlanProvider?.filterPredicate
        }
        self.allFlightPlans = CoreDataManager.shared.loadAllFlightPlanViewModels(predicate: predicate)
    }
}

// MARK: - FlightPlansListDelegate
extension FlightPlansListViewController: FlightPlansListDelegate {
    func flightPlansUpdated() {
        updateDataSource()
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlansListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allFlightPlans.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanCollectionViewCell
        if indexPath.row < allFlightPlans.count {
            let flightPlan = allFlightPlans[indexPath.row]
            let isSelected = displayMode == .full ? false : selectedFlightPlanUuid == flightPlan.state.value.uuid
            cell.configureCell(viewModel: flightPlan,
                               isSelected: isSelected)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FlightPlansListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < allFlightPlans.count else { return }

        let flightPlan = allFlightPlans[indexPath.row]
        selectedFlightPlanUuid = flightPlan.state.value.uuid
        delegate?.didSelect(flightPlan: flightPlan)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlightPlansListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // remove left and right insets.
        let collectionViewWidth = collectionView.frame.width - 2 * Constants.itemSpacing
        let nbColumns = UIApplication.isLandscape ? Constants.nbColumnsLandscape : Constants.nbColumnsPortrait
        let width = collectionViewWidth / nbColumns - Constants.itemSpacing
        let size = CGSize(width: width, height: width * Constants.cellWidthRatio)
        return size
    }
}
