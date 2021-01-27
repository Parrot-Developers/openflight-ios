// Copyright (C) 2020 Parrot Drones SAS
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

/// View that is positionned at the right of the stream.
/// Used as a control for HUD's split screen fonctionnality.

final class HUDSplitView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var handleView: UIView!
    @IBOutlet private weak var whiteView: UIView!

    // MARK: - Private Enums
    private enum Constants {
        static let animationDuration: TimeInterval = 0.4
        static let animationDelay: TimeInterval = 0.2
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitHUDSplitView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitHUDSplitView()
    }

    // MARK: - Internal Funcs
    /// Starts a blinking animation over the view.
    func startAnimation() {
        UIView.animate(withDuration: Constants.animationDuration,
                       delay: Constants.animationDelay,
                       options: [.autoreverse, .repeat],
                       animations: { [weak self] in
                        self?.whiteView.alpha = 1.0
        })
    }

    /// Stops the blinking animation.
    func stopAnimation() {
        self.layer.removeAllAnimations()
        whiteView.alpha = 0.0
    }
}

// MARK: - Private Funcs
private extension HUDSplitView {
    /// Common init.
    func commonInitHUDSplitView() {
        self.loadNibContent()
        handleView.roundCornered()
    }
}
