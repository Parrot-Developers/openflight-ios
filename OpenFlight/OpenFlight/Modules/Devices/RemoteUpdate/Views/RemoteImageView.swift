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
import Reusable

/// View which displays progress view for an update.
final class RemoteImageView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var deviceImageView: UIImageView!

    // MARK: - Private Properties
    private var isFirstProgressUpdate = true
    private var lockProgress = false
    private var progress: Int = 0

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitRemoteImageView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitRemoteImageView()
    }

    // MARK: - Internal Funcs
    /// Update progress view.
    ///
    /// - Parameters:
    ///     - progress: current progress value
    ///     - animationDuration: duration of the animation
    func setProgress(_ progress: Int, animationDuration: TimeInterval) {
        if isFirstProgressUpdate {
            circleProgressView.setProgress(Float(progress)/100.0, duration: 0)
            self.progress = progress
            isFirstProgressUpdate = false
        } else if !lockProgress && progress > self.progress {
            circleProgressView.setProgress(Float(progress)/100.0, duration: animationDuration)
            self.progress = progress
        }
    }

    /// Fake progress update.
    ///
    /// - Parameters:
    ///     - progress: progress value
    ///     - duration: duration of the animation
    func lockCompleteProgress(_ progress: Int, duration: TimeInterval) {
        lockProgress = true
        circleProgressView.setProgress(Float(progress)/100.0, duration: duration)
    }

    /// Reset progress.
    func resetProgress() {
        lockProgress = false
        progress = 0
        circleProgressView.resetProgress()
    }

    /// Update the device image.
    ///
    /// - Parameters:
    ///     - image: device image
    func updateRemoteImage(image: UIImage) {
        deviceImageView.image = image
    }

    /// Displays only download step.
    func displayDownloadOnly() {
        deviceImageView.image = Asset.Drone.icDownloadFromServer.image
    }
}

// MARK: - Private Funcs
private extension RemoteImageView {
    /// Common Init.
    func commonInitRemoteImageView() {
        self.loadNibContent()
    }
}
