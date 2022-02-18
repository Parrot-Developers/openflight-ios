//    Copyright (C) 2021 Parrot Drones SAS
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

import Foundation

/// Protocol used to communicated between `FlightPlanListHeaderViewController` and `FlightPlanListViewModel`.
protocol FlightPlanListHeaderDelegate: AnyObject {
    /// Used to notify delegate of selected item.
    ///
    /// - Parameters:
    ///     - provider: provider cell, to give delegate information, about selected item
    func didSelectItemAt(_ provider: FlightPlanListHeaderCellProvider)
}

/// Controller that handles header of `FlightPlanListController` CollectionView.
class FlightPlanListHeaderViewController: UICollectionViewController {

    // MARK: - Propreties
    weak var delegate: FlightPlanListHeaderDelegate?

    // MARK: - Internal Properties
    private var providers: [FlightPlanListHeaderCellProvider] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(cellType: FlightPlanListHeaderCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return providers.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as FlightPlanListHeaderCell
        let value = providers[indexPath.row]

        cell.configure(
            with: FlightPlanListHeaderCellProvider(
                uuid: value.uuid,
                count: value.count,
                missionType: value.missionType,
                logo: value.logo,
                isSelected: value.isSelected
            )
        )
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        providers[indexPath.row].isSelected.toggle()
        delegate?.didSelectItemAt(providers[indexPath.row])
    }

    // MARK: - Public Funcs
    /// Configure internal variables
    ///
    /// - Parameters:
    ///     - provider: array of provider struct to setup variables and trigger didSet to reloadData
    func configure(provider: [FlightPlanListHeaderCellProvider]) {
        self.providers = provider
    }
}
