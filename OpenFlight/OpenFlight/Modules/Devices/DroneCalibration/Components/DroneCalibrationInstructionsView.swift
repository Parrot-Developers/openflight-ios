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
import Lottie
/// Custom view for calibration instruction.
final class DroneCalibrationInstructionsView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageViewHeightConstraintWRHR: NSLayoutConstraint!
    @IBOutlet private weak var firstLabel: UILabel!
    @IBOutlet private weak var secondLabel: UILabel!
    @IBOutlet private weak var itemsStackView: UIStackView!
    @IBOutlet private weak var animationView: UIView!
    // MARK: - Internal Properties
    var viewModel: DroneCalibrationInstructionsModel! {
        didSet {
            fill(with: viewModel)
        }
    }
    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitDroneCalibrationInstructionsView()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitDroneCalibrationInstructionsView()
    }
}
// MARK: - Private Funcs
private extension DroneCalibrationInstructionsView {
    /// Basic init.
    func commonInitDroneCalibrationInstructionsView() {
        self.loadNibContent()
        imageView.isHidden = false
        animationView.isHidden = true
    }
    /// Update the UI for a specific view model.
    ///
    /// - Parameters:
    ///    - viewModel: view model for the view.
    func fill(with viewModel: DroneCalibrationInstructionsModel) {
        imageView.image = viewModel.image
        imageViewHeightConstraint.priority = (viewModel.image == nil) ? UILayoutPriority(rawValue: 500) : UILayoutPriority(rawValue: 1000)
        imageViewHeightConstraintWRHR.priority = (viewModel.image == nil) ? UILayoutPriority(rawValue: 500) : UILayoutPriority(rawValue: 1000)
        firstLabel.text = viewModel.firstLabel
        firstLabel.textColor = viewModel.firstLabelColor
        firstLabel.textAlignment = viewModel.firstLabelAlignment
        secondLabel.text = viewModel.secondLabel
        secondLabel.textColor = viewModel.secondLabelColor
        secondLabel.textAlignment = viewModel.secondLabelAlignment
        itemsStackView.removeSubViews()
        for item in viewModel.items {
            let view = DroneCalibrationInstructionItemView()
            view.text = item
            itemsStackView.addArrangedSubview(view)
        }
    }
}
// MARK: - Internal Funcs
extension DroneCalibrationInstructionsView {
    /// Plays drone calibration animation.
    ///
    /// - Parameters:
    ///     - jsonFilePath: json file path.
    func playAnimation(filePath: String) {
        self.animationView.removeSubViews()
        self.animationView.isHidden = false
        self.imageView.isHidden = true
        let lottieAnimationView = AnimationView()
        lottieAnimationView.animation = Animation.filepath(filePath)
        lottieAnimationView.loopMode = .loop
        animationView.addWithConstraints(subview: lottieAnimationView)
        lottieAnimationView.play()
    }

    /// Clears animation view.
    func clearAnimation() {
        let lottieAnimationView = animationView.subviews.first(where: { $0 is AnimationView })
        lottieAnimationView?.removeFromSuperview()
        imageView.isHidden = false
    }
}
