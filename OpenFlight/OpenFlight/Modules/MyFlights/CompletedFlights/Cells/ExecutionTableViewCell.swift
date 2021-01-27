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
import Reusable

/// Execution TableView Cell.
/// NibLoadable is used for easier instanciation.
final class ExecutionTableViewCell: UITableViewCell, NibLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var typeImage: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var completionLabel: UILabel!

    // MARK: - Internal Properties
    var selectionHandler: (() -> Void)?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        // Setup UI.
        backgroundColor = ColorName.white12.color
        applyCornerRadius()
        titleLabel.makeUp()
        dateLabel.makeUp(and: .white50)
        completionLabel.makeUp()
        titleLabel.text = ""
        dateLabel.text = ""
        completionLabel.text = ""

        // Add global tap recognizer.
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTouchUpInside))
        self.addGestureRecognizer(tap)
    }
}

// MARK: - Internal Funcs
extension ExecutionTableViewCell {
    /// Setup.
    ///
    /// - Parameters:
    ///     - name: Flight Plan name
    ///     - icon: Flight Plan icon
    ///     - fpExecution: Flight Plan Execution
    func setup(name: String,
               icon: UIImage?,
               fpExecution: FlightPlanExecution?) {
        typeImage.image = icon
        titleLabel.text = name
        dateLabel.text = fpExecution?.startDate?.formattedString(dateStyle: .none,
                                                                 timeStyle: .medium) ?? Style.dash
        if fpExecution?.state != .completed {
            completionLabel.text = L10n.flightPlanRunStopped
            completionLabel.textColor = ColorName.redTorch.color
        } else {
            completionLabel.text = L10n.flightPlanRunCompleted
            completionLabel.textColor = ColorName.greenSpring.color
        }
    }
}

// MARK: - Private Funcs
private extension ExecutionTableViewCell {
    /// View tapped.
    @objc func viewTouchUpInside() {
        selectionHandler?()
    }
}
