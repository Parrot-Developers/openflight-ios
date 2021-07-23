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

/// Custom settings slider.
@IBDesignable
final class SettingsSlider: UISlider {
    // MARK: - Internal Properties
    var overLimitValue: Float? {
        didSet {
            addOverLimitSubview()
        }
    }

    // MARK: - Private Properties
    private var underLimitColor: UIColor = ColorName.highlightColor.color {
        didSet {
            updateSliderTint()
        }
    }
    private var thumbImage: UIImage? = Asset.Common.Slider.slider.image
    private var thumbView: UIImageView? {
        for view in self.subviews {
            if ((view as? UIImageView) != nil) && view.bounds.size.width == view.bounds.size.height {
                return (view as? UIImageView)
            }
        }

        return nil
    }

    // MARK: - Override Properties
    override var value: Float {
        didSet {
            updateSliderTint()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let overLimitColor: UIColor = ColorName.warningColor.color
        static let trackHeight: CGFloat = 2.0
        static let leadingTrailingMargin: CGFloat = 6.0
        static let overLimitMarkerHeight: CGFloat = 9.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        updateThumbImage(self.thumbImage)

        self.minimumTrackTintColor = underLimitColor
        self.maximumTrackTintColor = ColorName.defaultTextColor.color

        if let unwpThumbView = self.thumbView {
            unwpThumbView.tintColor = underLimitColor
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        addOverLimitSubview()
    }

    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newRect = super.trackRect(forBounds: bounds)
        newRect.size.height = Constants.trackHeight
        newRect.origin.x = Constants.leadingTrailingMargin
        newRect.size.width = bounds.size.width - 2 * Constants.leadingTrailingMargin
        return newRect
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return super.beginTracking(touch, with: event)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        updateSliderTint()
        return super.continueTracking(touch, with: event)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        updateSliderTint()
    }

    override func cancelTracking(with event: UIEvent?) {
        updateSliderTint()
    }

    // MARK: - Internal Funcs
    /// Updates image.
    ///
    /// - Parameters:
    ///     - image: image to set
    func updateThumbImage(_ image: UIImage?) {
        thumbImage = image
        self.setThumbImage(image, for: .normal)
        self.setThumbImage(image, for: .selected)
        self.setThumbImage(image, for: .highlighted)
        self.setThumbImage(image, for: .disabled)
    }
}

// MARK: - Private Funcs
private extension SettingsSlider {
    /// Add specific subview if the over limit is reached.
    func addOverLimitSubview() {
        removeSubview(withBackgroundColor: underLimitColor)

        guard let overLimitValue = overLimitValue,
              !overLimitValue.isNaN,
              maximumValue > minimumValue else {
            return
        }

        let overLimitRatio = (overLimitValue-minimumValue) / (maximumValue-minimumValue)
        var frame = self.frame
        frame.size.width = Constants.trackHeight
        frame.size.height = Constants.overLimitMarkerHeight
        let imageOffset = (self.thumbImage?.size.width ?? 0) / 2
        frame.origin.x = (self.frame.size.width - imageOffset * 2) * CGFloat(overLimitRatio) + imageOffset
        frame.origin.y = (self.frame.size.height - Constants.overLimitMarkerHeight) / 2

        let viewToAdd: UIView = UIView(frame: frame)
        viewToAdd.backgroundColor = underLimitColor
        if let uThumbView = self.thumbView {
            insertSubview(viewToAdd, belowSubview: uThumbView)
        }
    }

    /// Remove subview with a specific background color.
    ///
    /// - Parameters:
    ///    - color: background color to remove
    func removeSubview(withBackgroundColor color: UIColor) {
        for view in self.subviews where view.backgroundColor == color {
            view.removeFromSuperview()
        }
    }

    /// Update slider tint.
    func updateSliderTint() {
        if let overLimitValue = overLimitValue, value >= overLimitValue {
            minimumTrackTintColor = Constants.overLimitColor
        } else {
            minimumTrackTintColor = underLimitColor
        }
    }
}
