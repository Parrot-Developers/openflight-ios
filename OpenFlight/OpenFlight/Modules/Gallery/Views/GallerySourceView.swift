//    Copyright (C) 2022 Parrot Drones SAS
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

class GallerySourceView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var mainStackView: UIStackView!
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var storageLabel: UILabel!
    @IBOutlet fileprivate weak var circleProgressView: CircleProgressView!

    // MARK: - Private Properties
    private var storageRatio: Double = 0.0

    // MARK: - Private Enums
    private enum Constants {
        static let warningStorageLimit: Double = 0.75
        static let criticalStorageLimit: Double = 0.9
        static let circleBorderWidth: CGFloat = 2.0
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit() {
        loadNibContent()
        circleProgressView.borderWidth = Constants.circleBorderWidth
        circleProgressView.setProgress(Float(storageRatio))
    }
}

// MARK: - Internal Funcs
internal extension GallerySourceView {
    func setup(details: UserStorageDetails) {
        mainStackView.axis = .horizontal

        // Setup labels display.
        titleLabel.font = FontStyle.big.font(isRegularSizeClass)
        storageLabel.font = FontStyle.current.font(isRegularSizeClass)
        titleLabel.textAlignment = .left
        storageLabel.textAlignment = .left

        guard !details.isOffline else {
            offlineSetup(source: details)
            return
        }

        // Setup labels colors.
        iconImageView.tintColor = ColorName.defaultTextColor.color
        titleLabel.textColor = ColorName.defaultTextColor.color
        updateStorageLabelColor(ColorName.disabledTextColor.color)

        // Setup labels text.
        titleLabel.text = details.type.title
        iconImageView.image = details.image
        let storageText = L10n.galleryMemoryFree

        // Convert each value in Double to succeed to computation.
        storageRatio = Double(details.storageUsed ?? 0) / Double(details.storageCapacity ?? 1)
        let isStorageWarningLimitReached: Bool = storageRatio > Constants.warningStorageLimit
        let isStorageCriticalLimitReached: Bool = storageRatio > Constants.criticalStorageLimit

        if let capacity = details.storageCapacity {
            if let used = details.storageUsed {
                storageLabel.text = String(format: "%.1lf/%.1lf %@",
                                           max(0, capacity - used),
                                           capacity,
                                           storageText)
            } else {
                storageLabel.text = String(format: "-/%.1lf %@",
                                           capacity,
                                           storageText)
            }
        } else {
            storageLabel.text = "-"
        }

        // Setup progress circle.
        circleProgressView.bgStokeColor = ColorName.black40.color

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

// MARK: - Private Funcs
private extension GallerySourceView {
    /// Setup cell with offline display.
    ///
    /// - Parameters:
    ///    - source: GallerySource
    func offlineSetup(source: UserStorageDetails) {
        iconImageView.image = source.image
        iconImageView.tintColor = ColorName.disabledTextColor.color
        titleLabel.text = L10n.gallerySourceDroneMemory
        titleLabel.textColor = ColorName.disabledTextColor.color
        storageLabel.text = L10n.commonOffline
        storageLabel.textColor = ColorName.disabledTextColor.color
        storageRatio = 0.0
        circleProgressView.bgStokeColor = ColorName.black40.color
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
