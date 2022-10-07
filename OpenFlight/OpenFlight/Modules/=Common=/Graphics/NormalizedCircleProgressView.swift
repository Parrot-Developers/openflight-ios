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

import UIKit
import Reusable

/// A view to represent normalized circle progress view.
public final class NormalizedCircleProgressView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var progressView: CircleProgressView!
    @IBOutlet private weak var imageView: UIImageView!

    // MARK: - Private Enums

    public enum PublicConstants {
        public static let fakeProgress: Float = 95.0
    }

    private enum Constants {
        static let maxProgress: Float = 100.0
        static let normalizedMaxProgress: Float = 1.0
        static let successOrErrorDuration: TimeInterval = 0.3
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitProgressView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitProgressView()
    }

    // MARK: - Internal Funcs
    /// Updates the image view.
    ///
    /// - Parameters:
    ///     - image: The image to update
    public func updateImage(image: UIImage) {
        imageView.image = image
    }

    /// Updates the progress.
    ///
    /// - Parameters:
    ///     - currentProgress: The current progress
    public func update(currentProgress: Float) {
        let normalizedProgress = currentProgress / Constants.maxProgress
        progressView.setProgress(normalizedProgress)
    }

    /// Fakes progress.
    ///
    /// - Parameters:
    ///     - progressEnd: progress end value
    ///     - duration: duration of the animation
    public func setFakeProgress(progressEnd: Float = PublicConstants.fakeProgress, duration: TimeInterval) {
        let normalizedProgress = progressEnd / Constants.maxProgress
        progressView.setProgress(normalizedProgress, duration: duration)
    }

    /// Fakes success or error progress.
    public func setFakeSuccessOrErrorProgress() {
        progressView.setProgress(Constants.normalizedMaxProgress,
                                 duration: Constants.successOrErrorDuration)
    }
}

// MARK: - Private Funcs
private extension NormalizedCircleProgressView {
    /// Common init.
    func commonInitProgressView() {
        self.loadNibContent()

        progressView.resetProgress()
    }
}
