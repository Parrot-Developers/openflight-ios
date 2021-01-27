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

/// Gallery Source Collection View Cell.

final class GallerySourceCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var mainStackView: UIStackView!
    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.backgroundColor = .clear
            bgView.applyCornerRadius()
        }
    }
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel! {
        didSet {
            titleLabel.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet fileprivate weak var storageLabel: UILabel! {
        didSet {
            storageLabel.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet fileprivate weak var circleProgressView: CircleProgressView!

    // MARK: - Private Properties
    private var storageRatio: Double = 0.0

    // MARK: - Private Enums
    private enum Constants {
        static let warningStorageLimit: Double = 0.75
        static let criticalStorageLimit: Double = 0.9
        static let circleBorderWidth: CGFloat = 2.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        circleProgressView.borderWidth = Constants.circleBorderWidth
        circleProgressView.setProgress(Float(storageRatio))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Prevent from missing redraw.
        circleProgressView.borderWidth = Constants.circleBorderWidth
        circleProgressView.setProgress(Float(storageRatio))
    }
}

// MARK: - Internal Funcs
internal extension GallerySourceCollectionViewCell {
    /// Setup cell.
    ///
    /// - Parameters:
    ///    - source: GallerySource
    ///    - isSelected: cell is selected
    func setup(source: GallerySource, isSelected: Bool) {
        guard !source.isOffline else {
            offlineSetup(source: source)
            return
        }

        let isCompact = !UIApplication.isLandscape
        mainStackView.axis = isCompact ? .vertical : .horizontal
        // Convert each value in Double to succeed to computation.
        storageRatio = Double(source.storageUsed) / Double(source.storageCapacity)
        let isStorageWarningLimitReached: Bool = storageRatio > Constants.warningStorageLimit
        let isStorageCriticalLimitReached: Bool = storageRatio > Constants.criticalStorageLimit
        // Setup labels display.
        if isCompact {
            titleLabel.makeUp()
            storageLabel.makeUp()
        } else {
            titleLabel.makeUp(with: .large)
            storageLabel.makeUp()
        }
        titleLabel.textAlignment = isCompact ? .center : .left
        storageLabel.textAlignment = isCompact ? .center : .left

        // Setup labels colors.
        bgView.backgroundColor = isSelected ? ColorName.white.color : .clear
        iconImageView.tintColor = isSelected ? ColorName.black.color : ColorName.white.color
        titleLabel.textColor = isSelected ? ColorName.black.color : ColorName.white.color
        let normalColor = isSelected ? ColorName.black.color : ColorName.white50.color
        if isStorageCriticalLimitReached && isCompact {
            updateStorageLabelColor(AlertLevel.critical.radarColor)
        } else if isStorageWarningLimitReached && isCompact {
            updateStorageLabelColor(AlertLevel.warning.radarColor)
        } else {
            updateStorageLabelColor(normalColor)
        }

        // Setup labels text.
        titleLabel.text = source.title
        iconImageView.image = source.image
        let storageText = isCompact ? L10n.galleryMemoryFreeCompact : L10n.galleryMemoryFree
        storageLabel.text = String(format: "%.1lf/%.1lf %@",
                                   (source.storageCapacity - source.storageUsed),
                                   source.storageCapacity,
                                   storageText)

        // Setup progress circle.
        circleProgressView.isHidden = isCompact
        if !isCompact {
            circleProgressView.bgStokeColor = isSelected ? ColorName.black40.color : ColorName.white20.color
            if isStorageCriticalLimitReached {
                updateCircleProgressColor(AlertLevel.critical.radarColor)
            } else if isStorageWarningLimitReached {
                updateCircleProgressColor(AlertLevel.warning.radarColor)
            } else {
                updateCircleProgressColor(AlertLevel.none.radarColor)
            }

            circleProgressView.setProgress(Float(storageRatio))
        }
    }
}
// MARK: - Private Funcs
private extension GallerySourceCollectionViewCell {
    /// Setup cell with offline display.
    ///
    /// - Parameters:
    ///    - source: GallerySource
    func offlineSetup(source: GallerySource) {
        titleLabel.makeUp()
        storageLabel.makeUp()
        titleLabel.text = source.title
        iconImageView.image = source.image
        bgView.backgroundColor = .clear
        iconImageView.tintColor = ColorName.white50.color
        titleLabel.textColor = ColorName.white50.color
        storageLabel.textColor = ColorName.white50.color
        storageLabel.text = L10n.commonOffline
        storageRatio = 0.0
        circleProgressView.bgStokeColor = ColorName.white20.color
        circleProgressView.setProgress(Float(storageRatio))
    }

    /// Updates the color of the circle progress with given color.
    ///
    /// - Parameters:
    ///    - color: color for the progress
    func updateCircleProgressColor(_ color: UIColor) {
        circleProgressView.strokeColor = color
    }

    /// Updates the color of the storage label with given color.
    ///
    /// - Parameters:
    ///    - color: color for the label
    func updateStorageLabelColor(_ color: UIColor) {
        storageLabel.textColor = color
    }
}
