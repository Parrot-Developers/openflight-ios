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

import UIKit
import Reusable
import Combine
import CoreLocation

final class FlightDetailsInfoCell: MainTableViewCell, NibReusable {
    @IBOutlet private weak var tagHeaderView: FlightTagHeaderView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var summaryView: FlightDetailsSummaryView!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var executionNameLabel: UILabel!

    private var cancellables = Set<AnyCancellable>()

    private var isEditingName = false {
        didSet {
            nameLabel.isHidden = isEditingName
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
        nameLabel.makeUp(with: .current, color: .defaultTextColor80)
        nameTextField.makeUp(style: .current, textColor: .defaultTextColor80, bgColor: .clear)
        executionNameLabel.makeUp(with: .current, color: .defaultTextColor80)
        separatorView.backgroundColor = ColorName.separator.color
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.forEach { $0.cancel() }
        cancellables = []
    }
}

private struct FlightSummaryProvider: FlightDetailsSummaryViewProvider {
    let duration: Double
    let batteryConsumption: Int
    let distance: Double
    let photoCount: Int
    let videoCount: Int

    init(flight: FlightModel) {
        duration = flight.duration
        batteryConsumption = Int(flight.batteryConsumption)
        distance = flight.distance
        photoCount = Int(flight.photoCount)
        videoCount = Int(flight.videoCount)
    }

    init (flights: [FlightModel]) {
        let sum = flights.reduce((duration: 0.0,
                                  battery: 0,
                                  distance: 0.0,
                                  photoCount: 0,
                                  videoCount: 0)) { sum, flight in
            return (duration: sum.duration + flight.duration,
                    battery: sum.battery + Int(flight.batteryConsumption),
                    distance: sum.distance + flight.distance,
                    photoCount: sum.photoCount + Int(flight.photoCount),
                    videoCount: sum.videoCount + Int(flight.videoCount))
        }
        duration = sum.duration
        batteryConsumption = sum.battery
        distance = sum.distance
        photoCount = sum.photoCount
        videoCount = sum.videoCount
    }
}

// MARK: - Cell configuration
extension FlightDetailsInfoCell {

    func configure(with provider: FlightPlanExecutionInfoCellProvider) {
        // disable editing
        isEditingName = false

        nameLabel.attributedText = nil
        nameLabel.text = provider.title
        executionNameLabel.text = provider.flightPlan.pictorModel.name
        tagHeaderView.text = provider.executionTitle
        tagHeaderView.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                         radius: Style.smallCornerRadius)

        dateLabel.text = provider.date

        if !provider.flights.isEmpty {
            summaryView.fill(provider: provider.summaryProvider)
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
        dateLabel.text = model.flight.startTime?.commonFormattedString

        // Summary
        summaryView.fill(provider: FlightSummaryProvider(flight: model.flight))

        // Execution Name
        executionNameLabel.isHidden = true

        // Add Subscribers
        listenNameTextFieldSubscribers()
        listenEditNameButtonSubscribers()
        listenFlightName()
    }

    private var title: String {
        get {
            nameLabel.attributedText?.string ?? ""
        }
        set {
            let font = nameLabel.font ?? ParrotFontStyle.huge.font
            let image = Asset.Common.Icons.iconEdit.image
            let attachement = NSTextAttachment(image: image)
            attachement.bounds = CGRect(x: 0,
                                        y: (font.capHeight - image.size.height).rounded() / 2,
                                        width: image.size.width,
                                        height: image.size.height)
            let text = NSMutableAttributedString(string: newValue + " ")
            text.append(NSAttributedString(attachment: attachement))
            nameLabel.attributedText = text
        }
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
                flightDetailsViewModel?.set(name: nameTextField.text ?? L10n.dashboardMyFlightUnknownLocation)
            }
            .store(in: &cancellables)

        /// TextField Did End Editing Publisher
        nameTextField.editingDidEndPublisher
            .sink { [unowned self] in
                // Update flight name
                isEditingName = false
                flightDetailsViewModel?.set(name: nameTextField.text ?? L10n.dashboardMyFlightUnknownLocation)
            }
            .store(in: &cancellables)
    }

    /// Listen Button states
    func listenEditNameButtonSubscribers() {
        nameLabel.tapGesturePublisher
            .sink { [unowned self] _ in
                isEditingName = true
                nameTextField.text = title
            }
            .store(in: &cancellables)
        nameLabel.isUserInteractionEnabled = true
    }

    /// Listen Flight name changes
    func listenFlightName() {
        flightDetailsViewModel?.$name
            .map { $0 ?? L10n.dashboardMyFlightUnknownLocation }
            .map { $0.isEmpty ? L10n.dashboardMyFlightUnknownLocation : $0 }
            .assign(to: \.title, on: self)
            .store(in: &cancellables)
    }
}
