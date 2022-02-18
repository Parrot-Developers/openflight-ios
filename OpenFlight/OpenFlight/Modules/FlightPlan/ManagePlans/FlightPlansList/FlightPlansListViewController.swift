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
        self.viewModel.initViewModel()
    }

    func setupViewModel(with viewModel: (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate), delegate: FlightPlansListViewModelDelegate) {
        self.viewModel = viewModel
        self.viewModel.setupDelegate(with: delegate)
        self.viewModel.initViewModel()
    }

    private func bindViewModel() {
        viewModel.allProjectsPublisher
            .sink { [unowned self] _ in
                collectionView?.reloadData()
                emptyLabelStack.isHidden = viewModel.projectsCount() > 0
            }
            .store(in: &cancellables)

        viewModel.uuidPublisher
            .dropFirst() // do not fire on initialization
            .sink { [unowned self] _ in
                collectionView?.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(cellType: FlightPlanCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self

        // Add double tap gesture recognizer for flight plan quick open action.
        collectionView.addDoubleTapRecognizer(target: self, action: #selector(didDoubleTap))

        emptyFlightPlansTitleLabel.text = L10n.flightPlanEmptyListTitle
        emptyFlightPlansDescriptionLabel.text = L10n.flightPlanEmptyListDesc
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView.reloadData()
        LogEvent.log(.screen(LogEvent.Screen.flightPlanList))
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Update layout when orientation changed.
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - UICollectionViewDataSource
extension FlightPlansListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.projectsCount()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanCollectionViewCell
        guard let cellProvider = viewModel.projectProvider(at: indexPath.row) else { return cell }
        cell.configureCell(project: cellProvider.project,
                           isSelected: cellProvider.isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FlightPlansListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectProject(at: indexPath.row)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FlightPlansListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.gridItemSize()
    }
}

extension FlightPlansListViewController {
    /// Collectionview's double tap action.
    /// Opens a filght plan if a double tap is detected on corresponding cell.
    ///
    /// - Parameters:
    ///    - sender: The double tap gesture recognizer.
    @objc func didDoubleTap(_ sender: UIGestureRecognizer) {
        // Get cell's index.
        guard let index = collectionView.indexPathForItem(at: sender.location(in: collectionView))?.item else { return }
        viewModel.openProject(at: index)
    }
}
