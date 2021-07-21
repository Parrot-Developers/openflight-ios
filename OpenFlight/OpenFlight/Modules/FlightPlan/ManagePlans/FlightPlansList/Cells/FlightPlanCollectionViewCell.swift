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

protocol FlightPlanCollectionDelegate: AnyObject {
    /// handles double tap cell
    ///
    /// -index: row of indexPath of cell
    func didDoubleTap(index: Int)
}

final class FlightPlanCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp()
        }
    }
    @IBOutlet private weak var dateLabel: UILabel! {
        didSet {
            dateLabel.makeUp(and: .greySilver)
        }
    }
    @IBOutlet private weak var typeImage: UIImageView!
    @IBOutlet private weak var selectedView: UIView!

    weak var delegate: FlightPlanCollectionDelegate?
    private var index: Int?

    // MARK: - Private Enums
    private enum Constants {
        /// Gradient layer start alpha.
        static let gradientStartAlpha: CGFloat = 0.0
        /// Gradient layer end alpha.
        static let gradientEndAlpha: CGFloat = 0.65
    }

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        self.applyCornerRadius(Style.largeCornerRadius)
        selectedView.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: ColorName.greenSpring.color,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.largeBorderWidth)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
        gesture.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(gesture)
    }

    @objc func didDoubleTap() {
        guard let index = index else { return }
        delegate?.didDoubleTap(index: index)
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradientView.addGradient(startAlpha: Constants.gradientStartAlpha,
                                 endAlpha: Constants.gradientEndAlpha,
                                 superview: self)
    }

    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                gradientView.backgroundColor = ColorName.white50.color
            } else {
                gradientView.backgroundColor = .clear
            }
        }
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - viewModel: flight plan view model
    ///     - isSelected: Whether cell is selected.
    ///     - index: cell current index
    func configureCell(viewModel: FlightPlanViewModel, isSelected: Bool, index: Int) {
        self.index = index
        let viewModelState = viewModel.state.value
        self.titleLabel.text = viewModelState.title ?? viewModelState.location?.coordinatesDescription
        self.dateLabel.text = viewModelState.date?.shortWithTimeFormattedString
        let defaultBackground = UIImage(asset: Asset.MyFlights.projectPlaceHolder)

        if let thumbnail = viewModelState.thumbnail {
            self.backgroundImageView.image = thumbnail
        } else {
            self.backgroundImageView.image = defaultBackground
        }

        if let type = viewModelState.type,
           type.missionMode.key != FlightPlanMissionMode.standard.rawValue {
            // Set image for custom Flight Plan types
            typeImage.image = type.icon
        } else {
            typeImage.image = nil
        }

        viewModel.state.valueChanged = { [weak self] state in
            if let thumbnail = state.thumbnail {
                self?.backgroundImageView.image = thumbnail
            } else {
                self?.backgroundImageView.image = defaultBackground
            }

            self?.layoutSubviews()
        }
        viewModel.requestThumbnail(thumbnailSize: self.frame.size)
        selectedView.isHidden = !isSelected
    }
}
