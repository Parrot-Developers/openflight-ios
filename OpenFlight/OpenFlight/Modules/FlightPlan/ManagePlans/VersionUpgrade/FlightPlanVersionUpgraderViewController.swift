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
import Combine

class FlightPlanVersionUpgraderViewController: UIViewController {
    // MARK: - Private Enums
    private enum Constants {
        static let dismissDelay: Double = 3.0
    }

    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var progressView: FlightPlanVersionUpgraderProgressView!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    // MARK: - Private Properties
    private var viewModel: FlightPlanVersionUpgraderViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    static func instantiate(viewModel: FlightPlanVersionUpgraderViewModel) -> FlightPlanVersionUpgraderViewController {
        let viewController = StoryboardScene.FlightPlanVersionUpgrader.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    var progress = 0
    var timer: Timer?

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        listenUpgradeState()
        viewModel.startUpgrade()
    }

    /// Initialize UI.
    func initUI() {
        // Avoid the ability to cancel the process.
        cancelButton.isHidden = true
        // Configure Title.
        titleLabel.text = "Data base Upgrade" // TODO: Fix wording and localize
        // Configure description.
        descriptionLabel.makeUp(with: .readingText, color: .defaultTextColor)
        // TODO: Fix wording and localize
        descriptionLabel.text = "The data base needs to be upgraded to use the app.\nPlease wait until the end of the process..."
    }

    /// Close the current screen.
    func closeView() {
        // Stop the progress if needed.
        progressView.stopIndeterminateProgress()
        // Dismiss the view.
        dismiss(animated: true)
    }

    func listenUpgradeState() {
        viewModel.$upgradeState
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                switch $0 {
                case .idle:
                    self.progressView.resetProgress()
                case .updating(progress: let progress):
                    self.progressView.update(percentProgress: progress)
                case .saving:
                    // TODO: Fix wording and localize
                    self.progressView.startIndeterminateProgress(text: "Finalizing")
                case .ended:
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.dismissDelay) {
                        self.closeView()
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Actions
private extension FlightPlanVersionUpgraderViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        dismiss(animated: true)
    }
}
