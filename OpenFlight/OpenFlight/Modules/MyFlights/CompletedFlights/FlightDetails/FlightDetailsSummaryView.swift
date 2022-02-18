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

import Reusable

protocol FlightDetailsSummaryViewProvider {
    var duration: Double { get }
    var batteryConsumption: Int { get }
    var distance: Double { get }
}

final class FlightDetailsSummaryView: UIView, NibOwnerLoadable {
    @IBOutlet private(set) weak var timeIcon: UIImageView!
    @IBOutlet private(set) weak var timeLabel: UILabel!
    @IBOutlet private(set) weak var batteryIcon: UIImageView!
    @IBOutlet private(set) weak var batteryLabel: UILabel!
    @IBOutlet private(set) weak var distanceIcon: UIImageView!
    @IBOutlet private(set) weak var distanceLabel: UILabel!

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.loadNibContent()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configurelabel(timeLabel, and: timeIcon, with: Asset.MyFlights.time.image)
        configurelabel(batteryLabel, and: batteryIcon, with: Asset.MyFlights.battery.image)
        configurelabel(distanceLabel, and: distanceIcon, with: Asset.MyFlights.distance.image)
     }

    func fill(provider: FlightDetailsSummaryViewProvider) {
        timeLabel.text = provider.duration.formattedString
        batteryLabel.text = Double(provider.batteryConsumption).asPercent()
        distanceLabel.text = UnitHelper.stringDistanceWithDouble(provider.distance)
    }
}

// MARK: - Internal
private extension FlightDetailsSummaryView {

    /// Configure Detail's label and icon
    func configurelabel(_ label: UILabel, and icon: UIImageView, with image: UIImage) {
        label.makeUp(with: .current, color: .defaultTextColor)
        label.adjustsFontSizeToFitWidth = true
        icon.image = image
            .withRenderingMode(.alwaysTemplate)
        icon.tintColor = ColorName.defaultTextColor.color
    }
}
