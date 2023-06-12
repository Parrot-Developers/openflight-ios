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

// MARK: - Protocols
protocol UpdatingDoneFooterDelegate: AnyObject {
    /// Quits the updating processes.
    func quitProcesses()
}

/// A view for updating process.
final class UpdatingDoneFooter: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var continueButton: ActionButton!

    // MARK: - Private Properties
    private weak var delegate: UpdatingDoneFooterDelegate?

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitUpdatingDoneFooter()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitUpdatingDoneFooter()
    }

    // MARK: - Internal Funcs
    /// Sets up the view.
    ///
    /// - Parameters:
    ///    - delegate:The delegate
    ///    - state:The state
    func setup(delegate: UpdatingDoneFooterDelegate?,
               state: UpdatingState) {
        self.delegate = delegate
        switch state {
        case .waiting:
            continueButton.isHidden = true
        case .error, .serialChange, .success:
            continueButton.isHidden = false
        }
    }
}

// MARK: - Actions
extension UpdatingDoneFooter {
    @IBAction func continueButtonTouchedUpInside(_ sender: Any) {
        delegate?.quitProcesses()
    }
}

// MARK: - Private Funcs
private extension UpdatingDoneFooter {
    /// Common init.
    func commonInitUpdatingDoneFooter() {
        self.loadNibContent()

        initUI()
    }

    /// Inits the UI.
    func initUI() {
        continueButton.setup(title: L10n.ok, style: .validate)
    }
}
