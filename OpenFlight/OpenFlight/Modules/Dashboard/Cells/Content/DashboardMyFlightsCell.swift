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
import Reusable
import Combine

/// My flights cell for dashboard collection view.
final class DashboardMyFlightsCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var tileView: MainTileView!
    @IBOutlet private weak var gradientView: LDGradientView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var totalDistanceLabel: UILabel!
    @IBOutlet private weak var totalTimeLabel: UILabel!
    @IBOutlet private weak var numberOfFlightLabel: UILabel!
    @IBOutlet private weak var syncLoaderImageView: UIImageView!

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private enum Constants {
        static let gradientStartColor = ColorName(rgbaValue: 0x41cf82ff).color
        static let gradientEndColor = ColorName(rgbaValue: 0x22916fff).color
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.removeAll()
        resetLabels()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    // MARK: - Internal Funcs
    /// Sets up flight view for information display.
    ///
    /// - Parameters:
    ///     - viewModel: cell's view model
    func setup(viewModel: DashboardMyFlightsCellModel) {
        cancellables = []
        titleLabel.text = L10n.dashboardMyFlightFlightLogs
        viewModel.summary
            .sink { [weak self] in
                self?.totalDistanceLabel.text = $0.totalFlightsDistance
                self?.totalTimeLabel.text = $0.totalFlightsDuration
                self?.numberOfFlightLabel.text = String($0.numberOfFlights)
            }
            .store(in: &cancellables)

        viewModel.isSynchronizingData
            .sink { [weak self] isSync in
                guard let self = self else { return }

                isSync ? self.syncLoaderImageView.startRotate() : self.syncLoaderImageView.stopRotate()
                self.syncLoaderImageView.isHidden = !isSync
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension DashboardMyFlightsCell {
    /// Instantiate text for version number and buttons.
    func initView() {
        gradientView.layer.cornerRadius = tileView.layer.cornerRadius
        gradientView.startColor = Constants.gradientStartColor
        gradientView.endColor = Constants.gradientEndColor
        gradientView.clipsToBounds = true
        totalDistanceLabel.makeUp()
        totalTimeLabel.makeUp()
        resetLabels()
    }

    func resetLabels() {
        let defaultValues = AllFlightsSummary.defaultValues
        totalDistanceLabel.text = defaultValues.totalFlightsDistance
        totalTimeLabel.text = defaultValues.totalFlightsDuration
        numberOfFlightLabel.text = String(defaultValues.numberOfFlights)
    }
}
