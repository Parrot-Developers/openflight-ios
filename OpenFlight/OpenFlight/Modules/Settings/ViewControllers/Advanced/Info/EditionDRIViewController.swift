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

import Combine
import SwiftyUserDefaults
import UIKit

final class EditionDRIViewController: UIViewController, UITableViewDelegate, SettingsSegmentedControlDelegate {
    // MARK: - Outlets
    @IBOutlet private weak var stackViewContainer: UIStackView!
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var closeButton: UIButton!
    // MARK: - Private Properties
    @IBOutlet private weak var toggleTitle: UILabel!
    @IBOutlet private weak var segmentControl: SettingsSegmentedControl!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var operatorNumberTextField: POFTextField!
    @IBOutlet private weak var associatedKeyTextField: POFTextField!
    @IBOutlet private weak var submitButton: LoaderButton!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var bottomViewConstraint: NSLayoutConstraint!
    private var coordinator: SettingsCoordinator?
    private var viewModel: SettingsNetworkViewModel!
    private var cancellables: Set<AnyCancellable> = []

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
        updateSubmitButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupBackgroundOverlayAnimation()
    }
}

// MARK: - Private Extension
private extension EditionDRIViewController {
    /// Initializes view.
    private func initUI() {
        let selectedIndex = viewModel.isOnEuropeanRegulation.toInt

        let segments = [SettingsSegment(title: L10n.commonNo, disabled: false, image: nil),
                        SettingsSegment(title: L10n.commonYes, disabled: false, image: nil)]
        segmentControl.segmentModel = SettingsSegmentModel(segments: segments,
                                                           selectedIndex: selectedIndex,
                                                           isBoolean: true)
        segmentControl.delegate = self
        toggleTitle.text = L10n.settingsEditDriRegulationDescription
        toggleTitle.makeUp(with: .readingText, color: .black)
        stackViewContainer.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        titleLabel.text = L10n.settingsConnectionDriName
        titleLabel.makeUp(with: .title, color: .defaultTextColor)
        initKeyboardObservers()

        descriptionLabel.makeUp(with: .readingText, color: .black)
        operatorNumberTextField.backgroundColor = Color(named: .whiteAlbescent)
        associatedKeyTextField.backgroundColor = Color(named: .whiteAlbescent)
        operatorNumberTextField.makeUp(style: .readingText, textColor: .defaultTextColor, bgColor: .whiteAlbescent)
        associatedKeyTextField.makeUp(style: .readingText, textColor: .defaultTextColor, bgColor: .whiteAlbescent)
        submitButton.setup(title: L10n.ok.uppercased(), style: .validate)
        errorLabel.text = ""
        errorLabel.makeUp(with: .current, color: .errorColor)

        operatorNumberTextField.setCustomBackgroundColor(color: Color(named: .whiteAlbescent))
        associatedKeyTextField.setCustomBackgroundColor(color: Color(named: .whiteAlbescent))

        operatorNumberTextField.text = viewModel.driOperatorFullId.mainEntry
        associatedKeyTextField.text = viewModel.driOperatorFullId.key
        associatedKeyTextField.isHidden = !viewModel.isOnEuropeanRegulation
        descriptionLabel.text = viewModel.isOnEuropeanRegulation ? L10n.settingsEditDriFullDescription : L10n.settingsEditDriShortDescription
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
        viewModel.dismissDriAlertPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.view.backgroundColor = .clear
                self.coordinator?.dismiss()
            }
            .store(in: &cancellables)

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
            })
            .store(in: &cancellables)

        operatorNumberTextField.editingChangedPublisher
            .sink { [weak self] textEntry in
                guard let self = self else { return }

                self.updateSubmitButton()
                self.operatorNumberTextField.text = String(textEntry.prefix(SettingsNetworkViewModel.driIdCharacterMaxCount))
            }
            .store(in: &cancellables)

        associatedKeyTextField.editingChangedPublisher
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateSubmitButton()
            }
            .store(in: &cancellables)

        operatorNumberTextField.returnPressedPublisher
            .merge(with: associatedKeyTextField.returnPressedPublisher)
            .sink { [weak self] _ in
                self?.submitDRI()
            }
            .store(in: &cancellables)
    }

    /// Adds gesture recognizers
    func addActions() {
        submitButton.addTarget(self, action: #selector(submitDRI), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(dismissVC), for: .touchUpInside)
    }

    /// Updates submit button if current dri entry differs from embed drone dri.
    func updateSubmitButton() {
        let isSubmitButtonEnabled = viewModel.isDriEntryNew(driId: operatorNumberTextField.text ?? "",
                                                  driKey: associatedKeyTextField.text ?? "",
                                                  isOnEuropeanRegulation: segmentControl.segmentModel?.selectedIndex == 1)
        submitButton.isEnabled = isSubmitButtonEnabled
    }

    /// Submit DRI inputs
    @objc func submitDRI() {
        viewModel.submitDRI(driId: operatorNumberTextField.text ?? "",
                            driKey: associatedKeyTextField.text ?? "",
                            isOnEuropeanRegulation: segmentControl.segmentModel?.selectedIndex == 1)
    }

    /// Dismisses the view controller.
    @objc func dismissVC() {
        viewModel.dismissDriEdition()
    }
}

// MARK: - KeyboardDelegate
extension EditionDRIViewController {
    /// Inits the keyboard visibility observers and the gesture recognizer.
    func initKeyboardObservers() {
        // Touch gesture that will dismiss the keyboard when clicking on the main view.
        let touchGesture = UITapGestureRecognizer(target: self,
                                                  action: #selector(dismissKeyboard))
        backgroundView.addGestureRecognizer(touchGesture)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Forces the keyboard to dismiss.
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }

    /// Moves up the scroll view when the keyboard will show.
    @objc func keyboardWillShow(sender: NSNotification) {
        // check if view is already at an upper position
        guard bottomViewConstraint.constant == 0 else { return }

        if let userInfo = sender.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            bottomViewConstraint.constant += keyboardFrame.size.height

            // Animate the view going to an upper position if possible.
            if let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
                UIView.animate(withDuration: duration, animations: {
                    self.view.layoutIfNeeded()
                })
            }
        }
    }

    /// Moves down the scroll view when the keyboard will hide.
    @objc func keyboardWillHide(sender: NSNotification) {
        bottomViewConstraint.constant = 0.0
        // Animate the scroll view going back to its initial place if possible.
        if let duration = sender.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            UIView.animate(withDuration: duration, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}

// MARK: - SegmentControlDelegate
extension EditionDRIViewController {
    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl, selectedSegmentIndex: Int) {
        descriptionLabel.text = selectedSegmentIndex == 1 ? L10n.settingsEditDriFullDescription : L10n.settingsEditDriShortDescription
        associatedKeyTextField.isHidden = selectedSegmentIndex == 0
        associatedKeyTextField.text = ""
        updateSubmitButton()
    }
}
