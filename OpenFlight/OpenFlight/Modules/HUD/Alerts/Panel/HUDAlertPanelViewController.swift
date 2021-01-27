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

// MARK: - Protocols
public protocol HUDAlertPanelDelegate: class {
    /// Shows alert panel view.
    func showAlertPanel()
    /// Hides alert panel view.
    func hideAlertPanel()
}

/// Manages HUD's left panel alert view.
final class HUDAlertPanelViewController: AlertPanelViewController {
    // MARK: - Outlets
    @IBOutlet private weak var actionButton: HUDAlertPanelActionButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var stopView: StopView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var goLabel: UILabel!
    @IBOutlet private weak var startView: UIView!

    // MARK: - Private Properties
    private var alertViewModel: HUDAlertPanelViewModel<HUDAlertPanelState>?

    // MARK: - Private Enums
    private enum Constants {
        static let totalProgress: Int = 3
    }

    // MARK: - Setup
    static func instantiate() -> HUDAlertPanelViewController {
        return StoryboardScene.HUDAlertPanel.initialScene.instantiate()
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        alertViewModel = nil
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HUDAlertPanelViewController {
    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        alertViewModel?.startAction()
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelViewController {
    /// Init the view.
    func initView() {
        // Default style.
        stopView.style = .cancelAlert
        stopView.delegate = self
        titleLabel.makeUp(with: .huge)
        subtitleLabel.makeUp(with: .large)
        actionButton.delegate = self
        startView.isHidden = true
        goLabel.text = L10n.commonGo.uppercased()
        goLabel.makeUp(with: .giant)
    }

    /// Inits the alert view model.
    func initViewModel() {
        alertViewModel = HUDAlertPanelViewModel(stateDidUpdate: { [weak self] state in
            self?.updatePanel(state: state)
        })

        guard let state = alertViewModel?.state else { return }

        updatePanel(state: state.value)
    }

    /// Updates panel for given state and notifies delegate to update display.
    ///
    /// - Parameters:
    ///    - state: current alert state to display
    func updatePanel(state: HUDAlertPanelState) {
        actionButton.stopProgress()

        guard let alert = state.currentAlert,
              state.canShowAlert else {
            delegate?.hideAlertPanel()
            return
        }

        delegate?.showAlertPanel()
        updateView(with: alert)
    }

    /// Updates panel view.
    ///
    /// - Parameters:
    ///    - alert: current alert state
    func updateView(with alert: AlertPanelState) {
        // Handle special cases according to the current alert.
        if alert.hasAnimation {
            actionButton.startProgressAnimation(delay: Double(alert.countdown ?? 0),
                                                countdownMessage: alert.countdownMessage)
        } else if alert.hasProgressView {
            updateProgressView(countdown: alert.countdown)
        }

        startView.isHidden = alert.startViewIsVisible == false
        stopView.style = alert.stopViewStyle ?? .classic
        actionButton.setupView(state: alert,
                               showActionLabel: alert.actionLabelIsVisible == true,
                               withText: alert.actionLabelText)
        actionButton.isEnabled = alert.state == .available

        // Starts or stops animation regarding state.
        switch alert.state {
        case .started:
            actionButton.startAnimation(state: alert)
        default:
            actionButton.stopAnimation(state: alert)
        }

        titleLabel.text = alert.title
        subtitleLabel.text = alert.subtitle
        subtitleLabel.textColor = alert.subtitleColor
        titleLabel.isHidden = false
    }

    /// Update progress view.
    ///
    /// - Parameters:
    ///    - countdown: current countdown
    func updateProgressView(countdown: Int?) {
        guard let countdown = countdown else {
            titleLabel.isHidden = true
            progressView.isHidden = true
            goLabel.isHidden = true
            return
        }

        progressView.setProgress(1.0 - Float(countdown / Constants.totalProgress), animated: true)
        progressView.isHidden = countdown == 0
        goLabel.isHidden = countdown != 0
    }
}

// MARK: - StopViewDelegate
extension HUDAlertPanelViewController: StopViewDelegate {
    func didClickOnStop() {
        alertViewModel?.cancelAction()
    }
}

// MARK: - HUDAlertPanelActionButtonDelegate
extension HUDAlertPanelViewController: HUDAlertPanelActionButtonDelegate {
    func startAction() {
        alertViewModel?.startAction()
    }
}
