//    Copyright (C) 2021 Parrot Drones SAS
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

/// A view to represent the data base upgrade progress.
final class FlightPlanVersionUpgraderProgressView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var progressView: CircleProgressView!
    @IBOutlet weak var progressText: UILabel!

    private var indeterminateTimer: Timer?

    // MARK: - Private Enums
    private enum Constants {
        static let maxProgress: Double = 100.0
        static let normalizedMaxProgress: Double = 1
        static let indeterminateProgressDuration: TimeInterval = 2
        static let indeterminateProgressInterval: TimeInterval = 5
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
    /// Updates the progress.
    ///
    /// - Parameter percentProgress: the current progress in percent
    func update(percentProgress: Double) {
        let normalizedProgress = percentProgress / Constants.maxProgress
        progressView.setProgress(Float(normalizedProgress))
        progressText.text = "\(Int(percentProgress))%"
    }

    /// Indeterminate progress.
    ///
    /// - Parameters:
    ///    - loopDuration: time in secconds to complete the progress circle view
    ///    - text: text in the middle of the progress view
    func startIndeterminateProgress(loopDuration: TimeInterval = Constants.indeterminateProgressDuration,
                                    text: String) {
        progressText.text = text
        indeterminateTimer = Timer.scheduledTimer(withTimeInterval: Constants.indeterminateProgressInterval, repeats: true) { [weak self] _ in
            self?.progressView.resetProgress()
            self?.progressView.setProgress(Float(Constants.normalizedMaxProgress),
                                           duration: loopDuration)
        }
        indeterminateTimer?.fire()
    }

    /// Stop the indeterminate progress.
    func stopIndeterminateProgress() {
        indeterminateTimer?.invalidate()
    }

    /// Reset progress view
    func resetProgress() {
        self.progressView.resetProgress()
    }
}

// MARK: - Private Funcs
private extension FlightPlanVersionUpgraderProgressView {
    /// Common init.
    func commonInit() {
        self.loadNibContent()
        progressText.makeUp(with: .title, color: .defaultTextColor)
        progressView.resetProgress()
        progressText.text = nil
    }
}
