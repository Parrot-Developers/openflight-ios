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
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "AlertPanel")
}

// MARK: - Protocols
public protocol HUDAlertPanelDelegate: AnyObject {
    /// The action button did click.
    func actionButtonDidClick()
}

/// Manages HUD's left panel alert view.
final class HUDAlertPanelViewController: AlertPanelViewController {
    // MARK: - Outlets
    @IBOutlet private weak var actionButton: HUDAlertPanelActionButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var stopView: StopView!
    @IBOutlet private weak var goLabel: UILabel!
    @IBOutlet private weak var startView: UIView!
    @IBOutlet private weak var containerRightSidePanel: RightSidePanelStackView!

    // MARK: - Private Properties
    private let alertViewModel = HUDAlertPanelViewModel<HUDAlertPanelState>(services: Services.hub)
    public weak var alertDelegate: HUDAlertPanelDelegate!

    // MARK: - Setup
    static func instantiate() -> HUDAlertPanelViewController {
        let controller = StoryboardScene.HUDAlertPanel.initialScene.instantiate()
        controller.alertDelegate = controller
        return controller
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        containerRightSidePanel.screenBorders = [.bottom]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        initViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        alertViewModel.state.valueChanged = nil
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
        alertDelegate.actionButtonDidClick()
    }
}

// MARK: - Private Funcs
private extension HUDAlertPanelViewController {
    /// Init the view.
    func initView() {
        // Default style.
        titleLabel.makeUp(with: .title, color: .defaultTextColor)
        subtitleLabel.makeUp(with: .current, color: .defaultTextColor)
        stopView.style = .cancelAlert
        stopView.delegate = self
        actionButton.delegate = self
        startView.isHidden = true
        goLabel.text = L10n.commonGo.uppercased()
        goLabel.makeUp(with: .giant, and: .defaultTextColor)
    }

    /// Inits the alert view model.
    func initViewModel() {
        alertViewModel.state.valueChanged = { [weak self] state in
            self?.updatePanel(state: state)
        }
        updatePanel(state: alertViewModel.state.value)
    }

    /// Updates panel for given state and notifies delegate to update display.
    ///
    /// - Parameters:
    ///    - state: current alert state to display
    func updatePanel(state: HUDAlertPanelState) {
        guard let alert = state.currentAlert, state.canShowAlert else {
            actionButton.stopProgress()
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
        if let type = alert.rthAlertType, let countdown = alert.countdown, let total = alert.initialCountdown {
            ULog.i(.tag, "type \(type) | countdown \(countdown)/\(total)")
        }

        if actionButton.rthAlertType != alert.rthAlertType {
            // Reset progress if we override an already on-going alert.
            actionButton.stopProgress()
            actionButton.rthAlertType = alert.rthAlertType
        }

        // Handle special cases according to the current alert.
        if alert.hasAnimation {
            if let countdown = alert.countdown {
                // Animate progress based on `alert.countdown` value.
                actionButton.startProgressAnimation(initialCountdown: alert.initialCountdown,
                                                    delay: Double(countdown),
                                                    countdownMessage: alert.countdownMessage)
            } else {
                // No countdown specified => launch default automatic progress animation.
                actionButton.launchCountdownAnimation()
            }
        } else if alert.hasTextCountdown {
            updateCountdown(alert: alert)
        }

        startView.isHidden = alert.startViewIsVisible == false
        stopView.style = alert.stopViewStyle ?? .classic
        stopView.isHidden = alert.stopViewStyle == .none
        actionButton.setupView(state: alert,
                               showActionLabel: alert.actionLabelIsVisible == true,
                               withText: alert.actionLabelText)
        actionButton.isEnabled = alert.state == .available

        if !alert.hasAnimation {
            // Starts or stops animation regarding state.
            switch alert.state {
            case .started:
                actionButton.startAnimation(state: alert)
            default:
                actionButton.stopAnimation(state: alert)
            }
        }

        titleLabel.text = alert.title
        subtitleLabel.text = alert.subtitle

        // Use .defaultTextColor if nil in order to avoid system textColor issues (dark mode).
        subtitleLabel.textColor = alert.subtitleColor ?? ColorName.defaultTextColor.color

        titleLabel.isHidden = false
    }

    /// Updates count down.
    ///
    /// - Parameters:
    ///    - alert: current alert state
    func updateCountdown(alert: AlertPanelState) {
        goLabel.isHidden = false
        if let countdownMessage = alert.countdownMessage,
           let countdown = alert.countdown {
            goLabel.text = countdownMessage(countdown)
        }
    }
}

// MARK: - StopViewDelegate
extension HUDAlertPanelViewController: StopViewDelegate {
    func didClickOnStop() {
        alertViewModel.cancelAction()
    }
}

// MARK: - HUDAlertPanelActionButtonDelegate
extension HUDAlertPanelViewController: HUDAlertPanelActionButtonDelegate {
    func progressDidFinish() {
        alertViewModel.progressDidFinish()
    }
}

// MARK: - HUDAlertPanelDelegate
extension HUDAlertPanelViewController: HUDAlertPanelDelegate {
    func actionButtonDidClick() {
        alertViewModel.startAction()
    }
}
