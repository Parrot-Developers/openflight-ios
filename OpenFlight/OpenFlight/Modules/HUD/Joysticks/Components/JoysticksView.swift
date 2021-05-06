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

import Reusable

/// Custom view which display left and right Joystick.

final class JoysticksView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var leftJoystickView: JoystickView!
    @IBOutlet private weak var rightJoystickView: JoystickView!

    // MARK: - Private Properties
    private let viewModel = JoysticksTypeViewModel()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitJoysticks()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitJoysticks()
    }
}

// MARK: - Private Funcs
private extension JoysticksView {
    func commonInitJoysticks() {
        self.loadNibContent()
        viewModel.state.valueChanged = { [weak self] state in
            self?.updateJoysticks(joysticksTypeState: state)
        }
        updateJoysticks(joysticksTypeState: viewModel.state.value)
    }

    /// Update each joystick's type regarding state.
    ///
    /// - Parameters:
    ///     - joysticksTypeState: type of joysticks
    func updateJoysticks(joysticksTypeState: JoysticksTypeState) {
        leftJoystickView.joystickType = joysticksTypeState.leftJoystickType
        rightJoystickView.joystickType = joysticksTypeState.rightJoystickType
    }
}
