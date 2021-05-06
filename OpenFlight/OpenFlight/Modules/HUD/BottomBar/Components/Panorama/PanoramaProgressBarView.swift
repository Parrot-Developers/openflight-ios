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

/// Custom view for panorama progress bar in the bottom bar of the HUD.
final class PanoramaProgressBarView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var progressBarBackView: UIView!
    @IBOutlet private weak var progressBarView: UIView!
    @IBOutlet private weak var panoramaTypeImage: UIImageView!
    @IBOutlet private weak var panoramaTypeLabel: UILabel!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var stopView: StopView! {
        didSet {
            self.stopView.delegate = self
            self.stopView.style = .panorama
        }
    }

    // MARK: - Private Properties
    private let panoramaModeViewModel = PanoramaModeViewModel()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitPanoramaProgressBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitPanoramaProgressBarView()
    }
}

// MARK: - Private Funcs
private extension PanoramaProgressBarView {
    func commonInitPanoramaProgressBarView() {
        self.loadNibContent()
        self.initUI()
        self.listenPanoramaMode()
    }

    /// Initalize UI for the view.
    func initUI() {
        self.progressBarBackView.cornerRadiusedWith(backgroundColor: ColorName.black60.color,
                                                    borderColor: .clear,
                                                    radius: Style.largeCornerRadius)
        self.progressBarView.backgroundColor = ColorName.greenSpring20.color
    }

    /// Starts watcher for panorama mode.
    func listenPanoramaMode() {
        self.panoramaModeViewModel.state.valueChanged = { [weak self] state in
            self?.updateProgressBar(state: state)
        }

        self.updateProgressBar(state: panoramaModeViewModel.state.value)
    }

    /// Updates elements of the progress bar.
    ///
    /// - Parameters:
    ///    - state: panorama mode state
    func updateProgressBar(state: PanoramaModeState) {
        self.panoramaTypeImage.image = state.mode.image
        self.panoramaTypeLabel.text = state.mode.title
        // TODO: Replace by image count when it will be ready on GSDK.
        self.progressLabel.text = "\(state.progress) %"
        self.progressBarWidthConstraint.constant = self.progressBarBackView.frame.width * (CGFloat(state.progress) / CGFloat(Values.oneHundred))
        self.progressBarView.layoutIfNeeded()
    }
}

// MARK: - StopViewDelegate
extension PanoramaProgressBarView: StopViewDelegate {
    func didClickOnStop() {
        self.panoramaModeViewModel.cancelPanoramaPhotoCapture()
    }
}
