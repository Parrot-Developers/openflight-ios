//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// A view to represent the firmware and missions updates progress.
final class FirmwareAndMissionProgressView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var progressView: CircleProgressView!

    // MARK: - Private Enums
    private enum Constants {
        static let maxProgress: Float = 100.0
        static let normalizedRebootProgress: Float = 0.95
        static let normalizedMaxProgress: Float = 1.0
        static let successOrErrorDuration: TimeInterval = 0.3
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitFirmwareAndMissionProgressView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitFirmwareAndMissionProgressView()
    }

    // MARK: - Internal Funcs
    /// Updates the progress.
    ///
    /// - Parameters:
    ///     - currentProgress: The current progress
    func update(currentProgress: Float) {
        let normalizedProgress = currentProgress / Constants.maxProgress
        progressView.setProgress(normalizedProgress)
    }

    /// Fakes reboot progress.
    ///
    /// - Parameters:
    ///     - duration: duration of the animation
    func setFakeRebootProgress(duration: TimeInterval) {
        progressView.setProgress(Constants.normalizedRebootProgress,
                                 duration: duration)
    }

    /// Fakes success or error progress.
    func setFakeSuccessOrErrorProgress() {
        progressView.setProgress(Constants.normalizedMaxProgress,
                                 duration: Constants.successOrErrorDuration)
    }
}

// MARK: - Private Funcs
private extension FirmwareAndMissionProgressView {
    /// Common init.
    func commonInitFirmwareAndMissionProgressView() {
        self.loadNibContent()

        progressView.resetProgress()
    }
}
