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

import Reusable

// MARK: - Internal Enums
/// Specify the update state of the device.
enum UpdateStep {
    case todo
    case doing
    case done
    case error
}

// MARK: - Internal Structs
/// Defines a model for a step of an update.
struct UpdateStepModel {
    var step: UpdateStep
    var title: String?
}

final class UpdateStepView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var stepLabel: UILabel!
    @IBOutlet private weak var stepIcon: UIImageView!

    // MARK: - Internal Properties
    var model: UpdateStepModel! {
        didSet {
            stepLabel.text = model.title
            fill(with: model)
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
}

// MARK: - Private Funcs
private extension UpdateStepView {
    /// Update the view.
    ///
    /// - Parameters:
    ///     - model: step of the update
    func fill(with model: UpdateStepModel) {
        switch model.step {
        case .doing:
            stepIcon.startRotate()
            updateView(.defaultTextColor, .highlightColor, Asset.Remote.icLoaderMini.image)
        case .done:
            stepIcon.stopRotate()
            updateView(.defaultTextColor, .highlightColor, Asset.Common.Checks.icChecked.image)
        case .error:
            stepIcon.stopRotate()
            updateView(.defaultTextColor, .errorColor, Asset.Remote.icErrorUpdate.image)
        default:
            updateView(.disabledTextColor, .clear, nil)
        }
    }

    /// Update the view.
    ///
    /// - Parameters:
    ///     - color: color of the step according to the state
    ///     - image: image of the step according to the state
    func updateView(_ textColor: ColorName, _ imageColor: ColorName, _ image: UIImage?) {
        stepIcon.image = image
        stepIcon.tintColor = UIColor(named: imageColor)
        stepLabel.textColor = UIColor(named: textColor)
    }
}
