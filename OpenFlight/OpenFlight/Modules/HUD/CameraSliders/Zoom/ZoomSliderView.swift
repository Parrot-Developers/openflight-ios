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

// MARK: - Protocols
/// Protocol describing zoom slider view commands.
protocol ZoomSliderViewDelegate: class {
    /// Called when camera should be zooming.
    func startZoom()
    /// Called when camera should be dezooming.
    func startDezoom()
    /// Called when camera should stop zooming.
    func stopZoom()
    /// Called when camera should reset zoom to default.
    func resetZoom()
}

// MARK: - Internal Enums

/// View displaying the deployed zoom controller.

final class ZoomSliderView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var zoomSlider: ZoomSlider!
    @IBOutlet private weak var zoomSubview: UIView!

    // MARK: - Internal Properties
    weak var delegate: ZoomSliderViewDelegate?
    weak var zoomState: CameraZoomState? {
        didSet {
            updateSlider()
        }
    }

    // MARK: - Private Properties
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!

    // MARK: - Private Enums
    private enum Constants {
        static let minimumZoomValue: Float = 1.0
        static let numberOfTaps: Int = 2
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        plusButton.roundCornered()
        minusButton.roundCornered()
        zoomSubview.roundCornered()
    }
}

// MARK: - Actions
private extension ZoomSliderView {
    /// Called when user holds down the minus button.
    @IBAction func minusButtonHoldDown(_ sender: Any) {
        delegate?.startDezoom()
    }

    /// Called when user holds down the plus button.
    @IBAction func plusButtonHoldDown(_ sender: Any) {
        delegate?.startZoom()
    }

    /// Called when user releases the minus button.
    @IBAction func minusButtonTouchedUpInside(_ sender: Any) {
        delegate?.stopZoom()
    }

    /// Called when user releases the plus button.
    @IBAction func plusButtonTouchedUpInside(_ sender: Any) {
        delegate?.stopZoom()
    }
}

// MARK: - Private Funcs
private extension ZoomSliderView {
    func commonInit() {
        self.loadNibContent()
        setDoubleTapGesture()
    }

    /// Sets up double tap gesture recognizer.
    func setDoubleTapGesture() {
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                            action: #selector(onDoubleTap))
        doubleTapGestureRecognizer.numberOfTapsRequired = Constants.numberOfTaps
        zoomSubview.addGestureRecognizer(doubleTapGestureRecognizer)
    }

    /// Called when a double tap on slider occurs.
    @objc func onDoubleTap(sender: UITapGestureRecognizer) {
        delegate?.resetZoom()
    }

    /// Updates the zoom slider with current state.
    func updateSlider() {
        guard let state = zoomState else {
            return
        }
        zoomSlider.maximumValue = Float(state.isLossyAllowed ? state.maxLossy : state.maxLossLess)
        zoomSlider.minimumValue = Constants.minimumZoomValue
        zoomSlider.overLimitValue = Float(state.maxLossLess)
        zoomSlider.value = Float(state.current)
    }
}
