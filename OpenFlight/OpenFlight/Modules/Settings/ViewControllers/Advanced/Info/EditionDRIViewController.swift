//    Copyright (C) 2022 Parrot Drones SAS
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
import Combine

final class EditionDRIViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var operatorNumberView: UIView!
    @IBOutlet private weak var operatorNumberTextField: UITextField!
    @IBOutlet private weak var associatedKeyView: UIView!
    @IBOutlet private weak var associatedKeyTextField: UITextField!
    @IBOutlet private weak var submitButton: LoaderButton!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!

    // MARK: - Private Properties
    private var coordinator: SettingsCoordinator?
    private var viewModel: SettingsNetworkViewModel!
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Constants
    private enum Constants {
        static let driIdCharacterCount: Int = 16
        static let driKeyCharacterCount: Int = 3
    }

    // MARK: - Init
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: settings coordinator
    ///     - viewModel: settings network model
    /// - Returns: an EditionDRIViewController.
    static func instantiate(coordinator: SettingsCoordinator,
                            viewModel: SettingsNetworkViewModel) -> EditionDRIViewController {
        let viewController = StoryboardScene.EditionDRIViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        addActions()
        addBinding()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBackgroundOverlayAnimation()
        operatorNumberTextField.becomeFirstResponder()
    }

    /// Initializes view.
    private func initUI() {
        containerView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        titleLabel.text = L10n.settingsConnectionDriName
        titleLabel.makeUp(with: .title, color: .defaultTextColor)
        descriptionLabel.text = L10n.settingsEditDriDescription
        descriptionLabel.makeUp(with: .readingText, color: .highlightColor)
        operatorNumberView.layer.cornerRadius = Style.mediumCornerRadius
        operatorNumberView.setBorder(borderColor: ColorName.defaultTextColor.color, borderWidth: 1)
        operatorNumberTextField.makeUp(style: .readingText, textColor: .defaultTextColor, bgColor: .clear)
        associatedKeyView.layer.cornerRadius = Style.mediumCornerRadius
        associatedKeyView.setBorder(borderColor: ColorName.defaultTextColor.color, borderWidth: 1)
        associatedKeyTextField.makeUp(style: .readingText, textColor: .defaultTextColor, bgColor: .clear)
        submitButton.setup(title: L10n.ok.uppercased(), style: .validate)
        errorLabel.text = ""
        errorLabel.makeUp(with: .current, color: .errorColor)
    }

    /// Present VC overlay animation
    private func setupBackgroundOverlayAnimation() {
        UIView.animate(
            withDuration: Style.shortAnimationDuration,
            delay: Style.shortAnimationDuration,
            animations: {
                self.view.backgroundColor = ColorName.nightRider80.color
            })
    }

    /// Listens view model
    private func addBinding() {
        viewModel.$isLoadingDri
            .sink(receiveValue: { [weak self] isLoading in
                guard let self = self else { return }
                isLoading ? self.submitButton.startLoader() : self.submitButton.stopLoader()
            })
            .store(in: &cancellables)

        viewModel.$errorMessageDri
            .sink(receiveValue: { [weak self] errorMessage in
                guard let self = self else { return }
                self.errorLabel.text = errorMessage
                self.setTexFieldsBorderColor(hasError: errorMessage != nil)
            })
            .store(in: &cancellables)

        viewModel.dismissDriAlertPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.view.backgroundColor = .clear
                self.coordinator?.dismiss()
            }
            .store(in: &cancellables)

        operatorNumberTextField.editingChangedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.operatorNumberTextField.text = String($0.prefix(Constants.driIdCharacterCount))
            }
            .store(in: &cancellables)

        associatedKeyTextField.editingChangedPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.associatedKeyTextField.text = String($0.prefix(Constants.driKeyCharacterCount))
            }
            .store(in: &cancellables)

        operatorNumberTextField.returnPressedPublisher
            .merge(with: associatedKeyTextField.returnPressedPublisher)
            .sink { [weak self] _ in
                self?.submitDRI()
            }
            .store(in: &cancellables)
    }

    /// Sets borders color of textfields
    ///
    /// - Parameters:
    ///     - hasError: True if the dri validation failed
    private func setTexFieldsBorderColor(hasError: Bool) {
        let borderColorName: ColorName = hasError ? .errorColor : .defaultTextColor
        operatorNumberView.layer.borderColor = borderColorName.color.cgColor
        associatedKeyView.layer.borderColor = borderColorName.color.cgColor
    }
}

private extension EditionDRIViewController {
    /// Adds gesture recognizers
    func addActions() {
        submitButton.addTarget(self, action: #selector(submitDRI), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
        let tapGestureDismissVC = UITapGestureRecognizer.init(target: self, action: #selector(dismissVC))
        backgroundView.addGestureRecognizer(tapGestureDismissVC)
    }

    /// Dismisses the view controller.
    @objc func dismissVC() {
        viewModel.dismissDriEdition()
    }

    /// Submits the DRI operator id and key.
    @objc func submitDRI() {
        viewModel.submitDRI(driId: operatorNumberTextField.text,
                             driKey: associatedKeyTextField.text,
                             driIdLength: Constants.driIdCharacterCount,
                             driKeyLength: Constants.driKeyCharacterCount)
    }
}
