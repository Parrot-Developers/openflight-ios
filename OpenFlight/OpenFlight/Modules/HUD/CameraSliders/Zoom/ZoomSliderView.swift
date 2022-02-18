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
import Combine
import Reusable

// MARK: - Internal Enums

/// Zoom slider view
final class ZoomSliderView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var zoomSlider: ZoomSlider!
    @IBOutlet private weak var zoomSubview: UIView!

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var doubleTapGestureRecognizer: UITapGestureRecognizer!
    var viewModel: ZoomSliderViewModel! {
        didSet {
            viewModel.$state.sink { [unowned self] in
                updateSlider($0)
            }
            .store(in: &cancellables)
        }
    }

    // MARK: - Private Enums
    private enum Constants {
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
        viewModel.minusButtonHoldDown()
    }

    /// Called when user holds down the plus button.
    @IBAction func plusButtonHoldDown(_ sender: Any) {
        viewModel.plusButtonHoldDown()
    }

    /// Called when user releases the minus button.
    @IBAction func minusButtonTouchedUpInside(_ sender: Any) {
        viewModel.minusButtonTouchedUp()
    }

    /// Called when user releases the plus button.
    @IBAction func plusButtonTouchedUpInside(_ sender: Any) {
        viewModel.plusButtonTouchedUp()
    }
}

// MARK: - Private Funcs
private extension ZoomSliderView {

    /// Should be called for any init
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
        viewModel.onDoubleTap()
    }

    /// Updates the zoom slider with current state.
    func updateSlider(_ state: ZoomSliderViewModel.State) {
        zoomSlider.maximumValue = state.max
        zoomSlider.minimumValue = state.min
        zoomSlider.overLimitValue = state.overLimit
        zoomSlider.value = state.value
    }
}
