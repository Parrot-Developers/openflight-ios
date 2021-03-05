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
import GroundSdk

// MARK: - Protocols
/// Gallery Loading View Delegate.
protocol GalleryLoadingViewDelegate: class {
    /// Should stop progress.
    func shouldStopProgress()
}

/// Gallery loading view.

final class GalleryLoadingView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var infoLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: GalleryLoadingViewDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let loadingViewTextOffset = 1
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitGalleryLoadingView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitGalleryLoadingView()
    }
}

// MARK: - Actions
private extension GalleryLoadingView {
    @IBAction func stopButtonDidTouchUpInside(_ sender: Any) {
        self.isHidden = true
        progressView.setProgress(0.0, animated: false)
        delegate?.shouldStopProgress()
    }
}

// MARK: - Internal Funcs
internal extension GalleryLoadingView {
    /// Set progress.
    ///
    /// - Parameters:
    ///    - progress: progress
    ///    - status: MediaTaskStatus
    func setProgress(_ progress: Float, status: MediaTaskStatus) {
        guard status == .running,
            progress > 0.0
            else {
                self.isHidden = true
                progressView.setProgress(0.0, animated: false)
                return
        }
        progressView.setProgress(progress, animated: true)
        self.isHidden = false
    }
}

// MARK: - Private Funcs
private extension GalleryLoadingView {
    func commonInitGalleryLoadingView() {
        self.loadNibContent()
        self.addBlurEffect(cornerRadius: 0.0)
        self.isHidden = true
        progressView.setProgress(0.0, animated: false)
        progressView.progressTintColor = ColorName.greenSpring20.color
        progressView.trackTintColor = .clear
        progressView.backgroundColor = .clear
        infoLabel.makeUp(with: .large)
        infoLabel.text = L10n.commonDownloading
        infoLabel.backgroundColor = .clear
    }
}
