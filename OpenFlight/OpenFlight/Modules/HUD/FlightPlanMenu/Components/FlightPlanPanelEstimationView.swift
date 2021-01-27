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
import Reusable

/// View that displays estimations for flight plan.
final class FlightPlanPanelEstimationView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var distanceItemView: FlightPlanPanelEstimationItemView!
    @IBOutlet private weak var durationItemView: FlightPlanPanelEstimationItemView!
    @IBOutlet private weak var memoryItemView: FlightPlanPanelEstimationItemView!

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitFlightPlanPanelEstimationView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitFlightPlanPanelEstimationView()
    }

    // MARK: - Public Funcs
    /// Updates estimations.
    ///
    /// - Parameters:
    ///     - model: Flight Plan estimations
    func updateEstimations(model: FlightPlanEstimationsModel?) {
        let estimations = model ?? FlightPlanEstimationsModel()
        distanceItemView.model = FlightPlanPanelEstimationItemModel(title: L10n.commonDistance,
                                                                    value: estimations.formattedDistance,
                                                                    detail: nil)
        durationItemView.model = FlightPlanPanelEstimationItemModel(title: L10n.commonDuration,
                                                                    value: estimations.formattedDuration,
                                                                    detail: nil)
        memoryItemView.model = FlightPlanPanelEstimationItemModel(title: L10n.commonMemory,
                                                                  value: estimations.formattedMemorySize,
                                                                  detail: nil)
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelEstimationView {
    /// Common init.
    func commonInitFlightPlanPanelEstimationView() {
        self.loadNibContent()
    }
}
