//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// View that contains the collectionView header, to be displayed on `FlightPlanListViewController` as header cells
class FlightPlanListReusableHeaderView: UICollectionReusableView {

    // MARK: - Properties
    static let identifier = String(describing: FlightPlanListReusableHeaderView.self)

    let headerCollectionView: FlightPlanListHeaderViewController = {
        let collection = StoryboardScene.FlightPlanListHeaderViewController.flightPlanListHeaderViewController.instantiate()
        collection.view.backgroundColor = .clear
        collection.view.translatesAutoresizingMaskIntoConstraints = false
        return collection
    }()

    // MARK: - init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Private Funcs
    private func setupUI() {
        addSubview(headerCollectionView.view)
        NSLayoutConstraint.activate([
            headerCollectionView.view.topAnchor.constraint(equalTo: topAnchor),
            headerCollectionView.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            headerCollectionView.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerCollectionView.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        backgroundColor = .clear
    }

    // MARK: - Public Funcs
    /// Configure internal variables
    ///
    /// - Parameters:
    ///     - provider: array of provider struct to setup variable of `headerCollectionView`
    ///     - delegate: delegation between `headerCollectionView` and `FlightPlanListViewModel`
    func configure(provider: [FlightPlanListHeaderCellProvider], delegate: FlightPlanListHeaderDelegate?) {
        headerCollectionView.configure(provider: provider)
        headerCollectionView.delegate = delegate
    }
}
