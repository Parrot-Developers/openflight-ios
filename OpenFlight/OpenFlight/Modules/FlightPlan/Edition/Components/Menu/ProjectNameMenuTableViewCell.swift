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
import Combine

final class ProjectNameTextField: UITextField {
    enum Constants {
        static let iconWidth = 12.0
    }
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let width = Constants.iconWidth
        return CGRect(origin: CGPoint(x: bounds.maxX - width, y: bounds.midY - width * 0.5),
                      size: CGSize(width: width, height: width))
    }
}

protocol ProjectNameMenuTableViewCellProvider: ProjectMenuTableViewCellProvider {
    var title: String { get set }
}

/// Project Menu TableView Cell.
final class ProjectNameMenuTableViewCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var projectNameTextField: UITextField!
    @IBOutlet private weak var projectTitleLabel: UILabel!
    @IBOutlet private weak var projectNameUnderline: UIView!
    private var provider: ProjectNameMenuTableViewCellProvider?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables = []
    }

    private func setupUI() {
        projectTitleLabel.makeUp(with: .caps, color: .disabledTextColor)
        projectTitleLabel.text = L10n.flightPlanProjectName.uppercased()

        projectNameTextField.makeUp(style: .largeMedium, textColor: .defaultTextColor, bgColor: .defaultBgcolor)

        projectNameTextField.clearButtonMode = .whileEditing
        projectNameTextField.tintColor = ColorName.defaultTextColor.color
        projectNameTextField.rightView = UIImageView(image: Asset.Common.Icons.iconEdit.image)
        projectNameTextField.rightViewMode = .unlessEditing
        projectNameUnderline.backgroundColor = ColorName.separator.color
    }

    private func listenNameTextFieldSubscribers() {
        projectNameTextField.returnPressedPublisher
            .sink { [unowned self] in
                provider?.title = projectNameTextField.text ?? ""
            }
            .store(in: &cancellables)
    }
}

// MARK: - Internal Funcs
extension ProjectNameMenuTableViewCell {
    /// Cell setup.
    ///
    /// - Parameters:
    ///     - provider: the provider of the cell
    func setup(with provider: ProjectNameMenuTableViewCellProvider) {
        self.provider = provider
        projectNameTextField.text = provider.title

        listenNameTextFieldSubscribers()
    }
}
