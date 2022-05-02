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

/// Flight TableViewCell.

final class FlightTableViewCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var dateView: UIView!
    @IBOutlet private weak var cellStackView: UIStackView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var yearLabel: UILabel!
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.customCornered(corners: [.allCorners], radius: Style.mediumCornerRadius)
        }
    }
    @IBOutlet private weak var mapImage: UIImageView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var photoStackView: UIStackView!
    @IBOutlet private weak var photoLabel: UILabel!
    @IBOutlet private weak var videoStackView: UIStackView!
    @IBOutlet private weak var videoLabel: UILabel!

    private var cancellables = Set<AnyCancellable>()

    private enum Constants {
        static let selectedBackgroundAlpha: CGFloat = 0.2
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - viewModel: Cell view model
    ///    - showDate: Show flight date
    func configureCell(viewModel: FlightTableViewCellModel, showDate: Bool) {
        cancellables = []

        // Add left screen borders for devices with notch
        screenBorders = [.left]

        // Style
        locationLabel.makeUp(with: .current, color: .defaultTextColor80)
        photoLabel.makeUp(with: .current, color: .defaultTextColor)
        videoLabel.makeUp(with: .current, color: .defaultTextColor)
        durationLabel.makeUp(with: .current, color: .defaultTextColor)

        // Setup date section display.
        dateView.isHidden = !(UIApplication.isLandscape || showDate)
        dateView.alpha = showDate ? 1.0 : 0.0
        cellStackView.axis =  UIApplication.isLandscape ? .horizontal : .vertical
        // Setup content.
        if showDate {
            let date = viewModel.flight.startTime
            monthLabel.text = date?.month.capitalized
            yearLabel.text = date?.year
        }
        dateLabel.text = viewModel.flight.shortFormattedDate
        durationLabel.text = viewModel.flight.shortFormattedDuration

        photoLabel.text = viewModel.flight.photoCount.description
        photoStackView.isHidden = viewModel.flight.photoCount == 0

        videoLabel.text = viewModel.flight.videoCount.description
        videoStackView.isHidden = viewModel.flight.videoCount == 0

        viewModel.$name
            .sink { [weak self] in
                self?.locationLabel.text = $0
            }
            .store(in: &cancellables)
        viewModel.$thumbnail
            .sink { [weak self] in
                self?.updateMapImage(viewModel: viewModel, thumbnail: $0)
            }
            .store(in: &cancellables)
        viewModel.$isSelected
            .sink { [weak self] selected in
                let bgColor: UIColor
                if selected {
                    bgColor = ColorName.highlightColor.color.withAlphaComponent(Constants.selectedBackgroundAlpha)
                } else {
                    bgColor = ColorName.white.color
                }
                self?.bgView.backgroundColor = bgColor
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Funcs
private extension FlightTableViewCell {

    func updateMapImage(viewModel: FlightTableViewCellModel, thumbnail: UIImage?) {
        if viewModel.flight.isLocationValid,
           let thumb = thumbnail {
            self.mapImage.image = thumb
        } else {
            self.mapImage.image = Asset.MyFlights.mapPlaceHolder.image
        }
    }
}
