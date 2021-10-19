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
import Combine
import CoreLocation

final class FlightDetailsInfoCell: UITableViewCell, NibReusable {
    @IBOutlet private weak var tagHeaderView: FlightTagHeaderView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet weak var nameStackView: UIStackView!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var editNameButton: UIButton!
    @IBOutlet private weak var locationView: FlightDetailsIconLabelView!
    @IBOutlet private weak var dateView: FlightDetailsIconLabelView!
    @IBOutlet private weak var summaryView: FlightDetailsSummaryView!

    private var cancellables = Set<AnyCancellable>()

    private var isEditingName = false {
        didSet {
            nameStackView.isHidden = isEditingName
            nameTextField.isHidden = !isEditingName
            if isEditingName {
                nameTextField.becomeFirstResponder()
            } else {
                nameTextField.resignFirstResponder()
            }
        }
    }

    private var flightDetailsViewModel: FlightDetailsViewModel?

    override func awakeFromNib() {
        super.awakeFromNib()

        dateView.label.makeUp(with: .large, and: .defaultIconColor)
        locationView.label.makeUp(with: .large, and: .defaultIconColor)
    }
}

private struct FlightSummaryProvider: FlightDetailsSummaryViewProvider {
    let duration: Double
    let batteryConsumption: Int
    let distance: Double

    init(flight: FlightModel) {
        duration = flight.duration
        batteryConsumption = Int(flight.batteryConsumption)
        distance = flight.distance
    }

    init (flights: [FlightModel]) {
        let sum = flights.reduce((duration: 0.0, battery: 0, distance: 0.0)) { sum, flight in
            return (duration: sum.duration + flight.duration,
                    battery: sum.battery + Int(flight.batteryConsumption),
                    distance: sum.distance + flight.distance)
        }
        duration = sum.duration
        batteryConsumption = sum.battery
        distance = sum.distance
    }
}

// MARK: - Cell configuration
extension FlightDetailsInfoCell {

    func configure(with provider: FlightPlanExecutionInfoCellProvider) {
        // disable editing
        isEditingName = false
        editNameButton.isHidden = true

        nameLabel.text = provider.title
        tagHeaderView.text = provider.executionTitle
        tagHeaderView.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                         radius: Style.smallCornerRadius)

        dateView.label.text = provider.date.formattedString(dateStyle: .medium, timeStyle: .short)
        dateView.icon.image = Asset.MyFlights.calendar.image
        dateView.isHidden = provider.date == Date.distantPast

        locationView.label.text = provider.location.coordinatesDescription
        locationView.icon.image = Asset.MyFlights.poi.image

        /// TODO: TFF7-135 summary
        if !provider.flights.isEmpty {
            summaryView.fill(provider: FlightSummaryProvider(flights: provider.flights))
        } else {
            summaryView.isHidden = true
        }
    }

    /// Populate cell for a FlightDetailsViewModel
    func configure(with model: FlightDetailsViewModel) {
        flightDetailsViewModel = model

        // Header
        tagHeaderView.text = L10n.dashboardMyFlightFlightLog.localizedUppercase
        tagHeaderView.cornerRadiusedWith(backgroundColor: ColorName.nightRider80.color,
                                         radius: Style.smallCornerRadius)

        // Flight Name
        isEditingName = false

        // Date
        dateView.label.text = model.flight.startTime?.formattedString(dateStyle: .medium, timeStyle: .short)
        dateView.icon.image = Asset.MyFlights.calendar.image

        // Location
        locationView.label.text = model.flight.coordinateDescription
        locationView.icon.image = Asset.MyFlights.poi.image

        // Summary
        summaryView.fill(provider: FlightSummaryProvider(flight: model.flight))

        // Add Subscribers
        listenNameTextFieldSubscribers()
        listenEditNameButtonSubscribers()
        listenFlightName()
    }
}

// MARK: - Subscribers
private extension FlightDetailsInfoCell {

    /// Listen TextField states
    func listenNameTextFieldSubscribers() {
        /// TextField Return Key Pressed Publisher
        nameTextField.returnPressedPublisher
            .sink { [unowned self] in
                // Exit editing mode
                isEditingName = false
                nameLabel.text = nameTextField.text ?? L10n.dashboardMyFlightUnknownLocation
            }
            .store(in: &cancellables)

        /// TextField Did End Editing Publisher
        nameTextField.editingDidEndPublisher
            .sink { [unowned self] in
                // Update flight name
                flightDetailsViewModel?.set(name: nameTextField.text ?? "")
            }
            .store(in: &cancellables)
    }

    /// Listen Button states
    func listenEditNameButtonSubscribers() {
        /// Button tapped Publisher
        editNameButton.onTapPublisher
            .sink { [unowned self] in
                // Enter editing mode
                isEditingName = true
                nameTextField.text = nameLabel.text
            }
            .store(in: &cancellables)
    }

    /// Listen Flight name changes
    func listenFlightName() {
        flightDetailsViewModel?.$name
            .map { $0 ?? L10n.dashboardMyFlightUnknownLocation }
            .map { $0.isEmpty ? L10n.dashboardMyFlightUnknownLocation : $0 }
            .assign(to: \.text, on: nameLabel)
            .store(in: &cancellables)
    }
}
