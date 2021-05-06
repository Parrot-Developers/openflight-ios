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
import Reusable

/// My flights cell for dashboard collection view.
final class DashboardMyFlightsCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var totalDistanceTitleLabel: UILabel!
    @IBOutlet private weak var totalDistanceLabel: UILabel!
    @IBOutlet private weak var totalTimeTitleLabel: UILabel!
    @IBOutlet private weak var totalTimeLabel: UILabel!
    @IBOutlet private weak var lastFlightDistanceTitleLabel: UILabel!
    @IBOutlet private weak var lastFlightDistanceLabel: UILabel!
    @IBOutlet private weak var lastFlightTimeTitleLabel: UILabel!
    @IBOutlet private weak var lastFlightTimeLabel: UILabel!
    @IBOutlet private weak var numberOfFlightLabel: UILabel!

    // MARK: - Private Enums
    private enum Constants {
        static let defaultTime: String = "0:00"
        static let defaultDistance: String = UnitHelper.formattedStringDistanceWithDouble(0.0)
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()

        numberOfFlightLabel.text = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    // MARK: - Internal Funcs
    /// Sets up flight view for information display.
    ///
    /// - Parameters:
    ///     - state: Base model state protocol used to get all necessary date about flights.
    func setup(state: ViewModelState) {
        let myFlightState = state as? MyFlightsState

        titleLabel.text = L10n.dashboardMyFlightsTitle.uppercased()
        totalDistanceTitleLabel.text = L10n.dashboardMyFlightsTotalDistance.uppercased()
        totalDistanceLabel.text = myFlightState?.totalFlightsDistance ?? Constants.defaultDistance
        totalTimeTitleLabel.text = L10n.dashboardMyFlightsTotalTime.uppercased()
        totalTimeLabel.text = myFlightState?.totalFlightsDuration ?? Constants.defaultTime
        lastFlightDistanceTitleLabel.text = L10n.dashboardMyFlightsSubtitle.uppercased()
        lastFlightDistanceLabel.text = myFlightState?.distance ?? Constants.defaultDistance
        lastFlightTimeTitleLabel.text = L10n.dashboardMyFlightsLastFlightTime.uppercased()
        lastFlightTimeLabel.text = myFlightState?.duration ?? Constants.defaultTime
        numberOfFlightLabel.text = String(myFlightState?.numberOfFlights ?? 0)
    }
}

// MARK: - Private Funcs
private extension DashboardMyFlightsCell {
    /// Instantiate text for version number and buttons.
    func initView() {
        titleLabel.makeUp(with: .small)
        totalDistanceTitleLabel.makeUp(with: .tiny, and: .white50)
        totalDistanceLabel.makeUp()
        totalTimeTitleLabel.makeUp(with: .tiny, and: .white50)
        totalTimeLabel.makeUp()
        lastFlightTimeTitleLabel.makeUp(with: .tiny, and: .white50)
        lastFlightTimeLabel.makeUp()
        lastFlightDistanceTitleLabel.makeUp(with: .tiny, and: .white50)
        lastFlightDistanceLabel.makeUp()
    }
}
