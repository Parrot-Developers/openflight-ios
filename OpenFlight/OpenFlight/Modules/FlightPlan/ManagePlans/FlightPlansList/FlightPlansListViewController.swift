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
import Combine

/// Manages a flight plan list.
final class FlightPlansListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyFlightPlansTitleLabel: UILabel!
    @IBOutlet private weak var emptyFlightPlansDescriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!

    // MARK: - Internal Properties
    private var viewModel: (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate)!
    private var cancellables = [AnyCancellable]()

    func setupViewModel(with viewModel: (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate)) {
        self.viewModel = viewModel
        self.viewModel.initialized()
    }

    func setupViewModel(with viewModel: (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate), delegate: FlightPlansListViewModelDelegate) {
        self.viewModel = viewModel
        self.viewModel.setupDelegate(with: delegate)
        self.viewModel.initialized()
    }

    private func bindViewModel() {
        viewModel.allFlightPlansPublisher
            .sink { [unowned self] _ in
                self.collectionView?.reloadData()
                self.emptyLabelStack.isHidden = self.viewModel.modelsCount() > 0
            }
            .store(in: &cancellables)

        viewModel.uuidPublisher
            .sink { [unowned self] _ in
                self.collectionView?.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Enums
    private enum Constants {
        static let nbColumnsLandscapeFull: CGFloat = 4.0
        static let nbColumnsLandscapeCompact: CGFloat = 3.0
        static let nbColumnsPortrait: CGFloat = 2.0
        static let itemSpacing: CGFloat = 10.0
        static let cellWidthRatio: CGFloat = 0.9
        static let heightHeader: CGFloat = 50.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(FlightPlanListReusableHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: FlightPlanListReusableHeaderView.identifier)
        collectionView.register(cellType: FlightPlanCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        emptyFlightPlansTitleLabel.text = L10n.flightPlanEmptyListTitle
        emptyFlightPlansDescriptionLabel.text = L10n.flightPlanEmptyListDesc
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.collectionView.reloadData()
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightPlanList,
                             logType: .screen)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Update layout when orientation changed.
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView
                .dequeueReusableSupplementaryView(ofKind: kind,
                                                  withReuseIdentifier: FlightPlanListReusableHeaderView.identifier,
                                                  for: indexPath) as? FlightPlanListReusableHeaderView
        else { return UICollectionReusableView() }
        header.configure(provider: viewModel.getHeaderProvider(), delegate: viewModel)
        return header
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlansListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.modelsCount()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanCollectionViewCell
        guard let cellProvider = viewModel.getFlightPlan(at: indexPath.row) else { return cell }
        cell.configureCell(project: cellProvider.project,
                           isSelected: cellProvider.isSelected,
                           index: indexPath.row)
        cell.delegate = self
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FlightPlansListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectedItem(at: indexPath.row)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlightPlansListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // remove left and right insets.
        let collectionViewWidth = collectionView.frame.width - 2 * Constants.itemSpacing
        let nbColumnsLadscape = viewModel.displayMode == .full ? Constants.nbColumnsLandscapeFull : Constants.nbColumnsLandscapeCompact
        let nbColumns = UIApplication.isLandscape ? nbColumnsLadscape : Constants.nbColumnsPortrait
        let width = collectionViewWidth / nbColumns - Constants.itemSpacing
        let size = CGSize(width: width, height: width)
        return size
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        if viewModel.displayMode == .full {
            return .init(width: self.collectionView.frame.width, height: Constants.heightHeader)
        }
        return .zero
    }
}

// MARK: - FlightPlanCollectionDelegate
extension FlightPlansListViewController: FlightPlanCollectionDelegate {
    func didDoubleTap(index: Int) {
        viewModel.openProject(at: index)
    }
}
