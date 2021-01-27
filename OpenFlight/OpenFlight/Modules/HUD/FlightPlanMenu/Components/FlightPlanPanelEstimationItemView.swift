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

// MARK: - Public Structs
/// Flight Plan Estimations Model.
public struct FlightPlanEstimationsModel: Equatable {
    // MARK: - Public properties
    /// Flight Plan distance, in meters.
    public var distance: Double?
    /// Flight Plan duration, in seconds.
    public var duration: TimeInterval? {
        // formattedDuration is not used as a computed property to prevent from extra computing.
        didSet {
            guard let duration = duration else {
                formattedDuration = Style.dash
                return
            }

            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .abbreviated
            formattedDuration = formatter.string(from: TimeInterval(duration)) ?? Style.dash
        }
    }
    /// Flight Plan memory size, in bytes.
    public var memorySize: UInt64? {
        // formattedMemorySize is not used as a computed property to prevent from extra computing.
        didSet {
            guard let memorySize = memorySize else {
                formattedMemorySize = Style.dash
                return
            }

            formattedMemorySize = StorageUtils.sizeForFile(size: memorySize)
        }
    }

    // MARK: - Internal properties
    private (set) var formattedDuration: String = Style.dash
    private (set) var formattedMemorySize: String = Style.dash
    /// Distance formatter in right measurement system.
    /// Formatted distance is computed because it may change regarding measurement system.
    var formattedDistance: String {
        guard let distance = distance else {
            return Style.dash
        }

        return UnitHelper.stringDistanceWithDouble(distance)
    }
}

/// Model for `FlightPlanPanelEstimationView`.
struct FlightPlanPanelEstimationItemModel {
    var title: String
    var value: String
    var detail: String?
}

/// View that display an estimation for flight plan (e.g.: distance, duration).
final class FlightPlanPanelEstimationItemView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp()
        }
    }
    @IBOutlet private weak var valueLabel: UILabel! {
        didSet {
            valueLabel.makeUp(and: .white50)
        }
    }
    @IBOutlet private weak var detailLabel: UILabel! {
        didSet {
            detailLabel.makeUp(and: .white50)
        }
    }

    // MARK: - Internal Properties
    var model: FlightPlanPanelEstimationItemModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitFlightPlanPanelEstimationItemView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitFlightPlanPanelEstimationItemView()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelEstimationItemView {
    /// Setup.
    func commonInitFlightPlanPanelEstimationItemView() {
        self.loadNibContent()
    }

    /// Updates the view with current model.
    func fill() {
        titleLabel.text = model?.title
        valueLabel.text = model?.value
        detailLabel.text = model?.detail
    }
}
