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

import Foundation
import Combine

/// View Controller used to display the cellular debug logs.
final class CellularDebugLogsViewController: UIViewController {

    // MARK: - Outlet

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var panelContainer: UIView! {
        didSet {
            panelContainer.backgroundColor = ColorName.white.color
            panelContainer.customCornered(corners: [.topLeft, .topRight],
                                          radius: Style.largeCornerRadius)
        }
    }

    // MARK: - Private Properties

    private var viewModel: CellularDebugLogsViewModel!
    private var cancellables = Set<AnyCancellable>()
    /// Whether autoscroll is enabled.
    private var autoscrollEnabled = true

    // MARK: - Setup

    /// Instantiates the view controller.
    ///
    /// - Parameters:
    ///     - viewModel: the view model used by the controller
    ///
    /// - Returns: a new view controller
    static func instantiate(viewModel: CellularDebugLogsViewModel) -> CellularDebugLogsViewController {
        let viewController = StoryboardScene.CellularDebugLogs.cellularDebugLogsViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(
            withDuration: Style.shortAnimationDuration,
            delay: Style.shortAnimationDuration) {
                self.view.backgroundColor = ColorName.nightRider80.color
            }

        LogEvent.log(.screen(LogEvent.Screen.debugLogs))
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = .clear
    }

    override func viewDidLayoutSubviews() {
        // scroll text view to show last message
        autoscroll()

        // show scroll indicators momentarily
        logsTextView.flashScrollIndicators()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    /// Function called when you dismiss the view.
    @IBAction func dismissPanelTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton( LogEvent.LogKeyCommonButton.back))
        viewModel.dismissView()
    }
}

// MARK: - UI Setup

private extension CellularDebugLogsViewController {

    func initUI() {
        titleLabel.text = L10n.drone4gConnectionDebug
        logsTextView.textColor = ColorName.defaultTextColor.color
        logsTextView.backgroundColor = .white
        logsTextView.indicatorStyle = .black
        logsTextView.delegate = self
        view.backgroundColor = .clear
    }

    func bindViewModel() {
        viewModel.$logMessages
            .removeDuplicates()
            .sink { [unowned self] logMessages in
                self.updateLogMessages(logMessages: logMessages)
            }
            .store(in: &cancellables)
    }

    /// Updates log messages view.
    ///
    /// - Parameters:
    ///     - logMessages: log messages
    func updateLogMessages(logMessages: [String]) {
        // colorize and join log messages
        let attributedLogMessages = logMessages.reduce(NSMutableAttributedString()) { attributedText, logMessage in
            let attributedLogMessage = NSMutableAttributedString(string: logMessage + "\n")
            attributedLogMessage.addAttribute(NSAttributedString.Key.foregroundColor,
                                              value: ColorName.warningColor.color,
                                              range: NSRange(location: 0, length: 14))
            attributedText.append(attributedLogMessage)
            return attributedText
        }

        // update displayed text
        logsTextView.attributedText = attributedLogMessages

        // scroll text view to show last message
        autoscroll()

        // show scroll indicators momentarily
        logsTextView.flashScrollIndicators()
    }

    /// Scrolls text view to show last message, if autoscroll is enabled.
    func autoscroll() {
        if autoscrollEnabled {
            let range = NSRange(location: logsTextView.text.count - 1, length: 0)
            logsTextView.scrollRangeToVisible(range)
        }
    }
}

/// Extension to conform `UITextViewDelegate`.
extension CellularDebugLogsViewController: UITextViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // disable autocroll when user scrolls
        autoscrollEnabled = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + 1) >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            // enabled autoscroll when bottom is reached
            autoscrollEnabled = true
        }
    }
}
