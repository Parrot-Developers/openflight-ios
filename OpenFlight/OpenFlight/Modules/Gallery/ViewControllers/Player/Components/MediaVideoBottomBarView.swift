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

import Reusable

enum MediaVideoSliderStyle {
    case full, minimal

    var thumbImage: UIImage? {
        switch self {
        case .full: return Asset.Common.Slider.slider.image
        case .minimal: return UIImage()
        }
    }
}

/// Protocol for `MediaVideoBottomBar`.
protocol MediaVideoBottomBarViewDelegate: AnyObject {
    /// Called when slider moved.
    func didUpdateSlider(newPositionValue: TimeInterval)
}

/// Class definition for `MediaVideoBottomBarView`.
final class MediaVideoBottomBarView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var slider: SettingsSlider!
    @IBOutlet private weak var timingInfosView: UIStackView!
    @IBOutlet private weak var positionLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: MediaVideoBottomBarViewDelegate?
    var sliderStyle: MediaVideoSliderStyle = .full {
        didSet {
            updateSliderStyle()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Internal Funcs
    /// Update slider to position in parameter.
    ///
    /// - Parameters:
    ///    - position: Current position
    ///    - duration: Media duration
    func updateSlider(position: TimeInterval, duration: TimeInterval) {
        guard !slider.isTracking else { return }
        slider.maximumValue = Float(duration)
        durationLabel.text = duration.formattedString
        positionLabel.text = position.formattedString
        slider.setValue(Float(position), animated: true)
        showFromEdge(.bottom, show: duration != 0, fadeFrom: 1) // hide bar if duration is 0
    }

    /// Updates slider's position.
    ///
    /// - Parameter position: the position to update the slider to
    func updateSlider(position: TimeInterval?) {
        guard !slider.isTracking else { return }
        guard let position = position else {
            slider.setValue(0, animated: false)
            return
        }
        positionLabel.text = position.formattedString
        slider.setValue(Float(position), animated: true)
    }

    /// Updates slider's duration.
    ///
    /// - Parameter duration: the duration to update the slider to
    func updateSlider(duration: TimeInterval?) {
        guard !slider.isTracking else { return }
        guard let duration = duration else {
            slider.maximumValue = 0
            showFromEdge(.bottom, show: false)
            return
        }
        slider.maximumValue = Float(duration)
        durationLabel.text = duration.formattedString
        showFromEdge(.bottom, show: duration != 0, fadeFrom: 1) // hide bar if duration is 0
    }

    func updateSliderStyle() {
        timingInfosView.showFromEdge(.bottom, show: sliderStyle == .full, fadeFrom: 1)
        slider.updateThumbImage(sliderStyle.thumbImage)
    }
}

// MARK: - Actions
private extension MediaVideoBottomBarView {
    @IBAction func sliderValueDidChange(_ sender: UISlider) {
        positionLabel.text = TimeInterval(slider.value).formattedString
        delegate?.didUpdateSlider(newPositionValue: TimeInterval(slider.value))
    }
}

// MARK: - Private Funcs
private extension MediaVideoBottomBarView {
    func commonInit() {
        loadNibContent()

        // Use .compact font size for all size classes.
        let font = FontStyle.big.font(false, monospacedDigits: true)
        positionLabel.font = font
        durationLabel.font = font

        // Prevents gesture conflicts, especially when placed in UIPageViewController.
        let panGesture = UIPanGestureRecognizer()
        panGesture.cancelsTouchesInView = false
        slider.addGestureRecognizer(panGesture)
    }
}
