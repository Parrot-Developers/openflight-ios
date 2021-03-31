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

/// Displays a record counter view inside Flight Plan's panel.
final class FlightPlanPanelMediaCounterView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var recordingStackView: UIStackView!
    @IBOutlet private weak var recordView: UIView!
    @IBOutlet private weak var recordCounterLabel: UILabel!

    // MARK: - Private Properties
    private var viewModel = RecordingTimeViewModel()

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitFlightPlanPanelMediaCounterView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitFlightPlanPanelMediaCounterView()
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelMediaCounterView {
    /// Common init.
    func commonInitFlightPlanPanelMediaCounterView() {
        self.loadNibContent()

        setupView()
        setupViewModel()
    }

    /// Sets up initial view display.
    func setupView() {
        recordView.roundCorneredWith(backgroundColor: ColorName.redTorch.color)
        recordCounterLabel.makeUp()
    }

    /// Sets up view model.
    func setupViewModel() {
        viewModel.state.valueChanged = { [weak self] state in
            self?.update(with: state)
        }

        update(with: viewModel.state.value)
    }

    /// Updates counter view with given state.
    ///
    /// - Parameters:
    ///    - state: state from `RecordingTimeViewModel`
    func update(with state: RecordingTimeState) {
        switch state.functionState {
        case .started:
            recordingStackView.isHidden = false
        case .stopped, .starting, .stopping:
            recordingStackView.isHidden = true
        }

        recordCounterLabel.text = state.recordingTime?.formattedString
    }
}
