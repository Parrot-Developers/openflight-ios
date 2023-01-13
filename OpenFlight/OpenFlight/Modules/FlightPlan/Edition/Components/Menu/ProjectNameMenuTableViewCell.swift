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

final class ProjectNameTextField: MainTextField {
    enum Constants {
        static let iconWidth = 12.0
        static let iconPadding = 10.0
    }
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let width = Constants.iconWidth
        return CGRect(origin: CGPoint(x: bounds.maxX - width - Constants.iconPadding, y: bounds.midY - width * 0.5),
                      size: CGSize(width: width, height: width))
    }
}

protocol ProjectNameMenuTableViewCellProvider: ProjectMenuTableViewCellProvider {
    var title: String { get set }
    // Informs whether the title must be displayed in edition mode (i.e. keyboard shown).
    var isTitleEditionNeeded: Bool { get }
}

/// Project Menu TableView Cell.
final class ProjectNameMenuTableViewCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var projectNameContainer: UIView!
    @IBOutlet private weak var projectNameTextField: UITextField!
    @IBOutlet private weak var projectTitleLabel: UILabel!
    private var provider: ProjectNameMenuTableViewCellProvider?

    private var cancellables = Set<AnyCancellable>()

    enum Constants {
        static let textFieldMaximumLength: Int = 32
    }
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

        projectNameTextField.makeUp(style: .current, textColor: .defaultTextColor, bgColor: .clear)

        projectNameTextField.clearButtonMode = .whileEditing
        projectNameTextField.tintColor = ColorName.defaultTextColor.color
        projectNameTextField.rightView = UIImageView(image: Asset.Common.Icons.iconEdit.image)
        projectNameTextField.rightViewMode = .unlessEditing
        projectNameTextField.enablesReturnKeyAutomatically = true

        projectNameContainer.backgroundColor = ColorName.whiteAlbescent.color
        projectNameContainer.layer.cornerRadius = Style.mediumCornerRadius
    }

    private func listenNameTextFieldSubscribers() {
        projectNameTextField.editingDidEndPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                // Prevent to update the title with empty text (should be handled by `enablesReturnKeyAutomatically`).
                guard let title = self.projectNameTextField.text,
                      !title.isEmpty else { return }
                // Update provider's title whenever the project's name textField edition ends.
                self.provider?.title = title
            }
            .store(in: &cancellables)

        projectNameTextField.returnPressedPublisher
            .sink { [weak self] in
                // Simply dismiss keyboard on return key press, as provider's title will be
                // updated on `editingDidEndPublisher` event.
                self?.projectNameTextField.resignFirstResponder()
            }
            .store(in: &cancellables)

        projectNameTextField.editingChangedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                if $0.count > Constants.textFieldMaximumLength {
                    self.projectNameTextField.text = String($0.prefix(Constants.textFieldMaximumLength))
                }
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
        // Display, if needed (e.g. project creation), the keyboard letting user to edit the title.
        if provider.isTitleEditionNeeded { projectNameTextField.becomeFirstResponder() }

        listenNameTextFieldSubscribers()
    }
}
