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
import GroundSdk

/// A View for Hello World AirSdk Mission.
final class HelloWorldBottomView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var stateView: BarButtonView! {
        didSet {
            stateView.currentMode.adjustsFontSizeToFitWidth = true
            stateView.currentMode.minimumScaleFactor = Style.minimumScaleFactor
            stateView.roundedCorners = [.topLeft, .bottomLeft]
        }
    }

    @IBOutlet private weak var startAndStopView: HelloWorldStartAndStopView! {
        didSet {
            self.startAndStopView.delegate = self
        }
    }

    // MARK: - Private Properties
    private let helloWorldMissionViewModel = HelloWorldMissionViewModel()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitHelloWorldModelView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitHelloWorldModelView()
    }
}

// MARK: - Private Funcs
private extension HelloWorldBottomView {
    func commonInitHelloWorldModelView() {
        self.loadNibContent()

        initUI()
        initViewModel()
    }

    /// Inits the view model.
    func initViewModel() {
        helloWorldMissionViewModel.state.valueChanged = { [weak self] state in
            let messageCount = state.messageReceivedCount
            self?.updateStackView(missionState: state.missionState,
                                  didReceiveMessage: messageCount > 0)
            self?.startAndStopView.update(with: state.missionState,
                                          didReceiveMessage: messageCount > 0)
        }
    }

    /// Inits the UI.
    func initUI() {
        updateStackView(missionState: .unavailable,
                        didReceiveMessage: false)
        startAndStopView.update(with: .unavailable,
                                didReceiveMessage: false)
    }

    /// Updates the stackView.
    ///
    /// - Parameters:
    ///     - missionState: The Mission State
    ///     - didReceiveMessage: A boolean to indicate if we received a message from the drone
    func updateStackView(missionState: MissionState, didReceiveMessage: Bool) {
        self.stateView.model = buttonStateModel(missionState: missionState,
                                                didReceiveMessage: didReceiveMessage)
    }

    /// Returns a BottomBarButtonState.
    ///
    /// - Parameters:
    ///     - missionManager: The Mission Manager
    ///     - didReceiveMessage: A boolean to indicate if we received a message from the drone
    /// - Returns: a BottomBarButtonState.
    func buttonStateModel(missionState: MissionState,
                          didReceiveMessage: Bool) -> BarButtonState {
        let subtext: String
        switch missionState {
        case .active:
            subtext = didReceiveMessage ? L10n.helloFeedback : L10n.helloSayHello
        case .idle, .unavailable, .unloaded, .activating:
            subtext = missionState.description
        }

        return BottomBarButtonState(title: L10n.commonAction.uppercased(),
                                    subtext: subtext)
    }
}

// MARK: - HelloWorldStartAndStopViewDelegate
extension HelloWorldBottomView: HelloWorldStartAndStopViewDelegate {
    func didClickOnStartAndStop() {
        helloWorldMissionViewModel.toggleState()
    }
}
