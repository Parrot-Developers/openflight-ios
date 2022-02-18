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
import Combine

/// Manages flight plan managing view.
final class ManagePlansViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var topBar: FileNavigationStackView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var projectTitle: UILabel! {
        didSet {
            projectTitle.makeUp(with: .huge, and: .defaultTextColor)
            projectTitle.text = L10n.flightPlanProjects
        }
    }
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var duplicateButton: ActionButton!
    @IBOutlet private weak var deleteButton: ActionButton!
    @IBOutlet private weak var newButton: ActionButton!
    @IBOutlet private weak var openButton: ActionButton!

    // MARK: - Private Enums
    private enum Constants {
        static let textFieldMaximumLength: Int = 50
        static let heightAccountView: CGFloat = 40
        static let trailingAccountView: CGFloat = -20
    }

    // MARK: - Private properties
    private var viewAccount: MyFlightsAccountView?
    private var viewModel: ManagePlansViewModelInput!
    private weak var coordinator: ManagePlansCoordinator?
    private var cancellables = [AnyCancellable]()
    private var tapAroundKeyboardSubscriber: AnyCancellable?
    private(set) weak var flightPlansListViewController: FlightPlansListViewController?

    // MARK: - Setup
    static func instantiate(viewModel: ManagePlansViewModel, coordinator: ManagePlansCoordinator) -> ManagePlansViewController {
        let viewController = StoryboardScene.ManagePlans.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        listenKeyboardPresentationChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update Account view
        // TODO: Refactor User Account Widget
        viewAccount?.viewWillAppear()
        LogEvent.log(.screen(LogEvent.Screen.flightPlanManageDialog))
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let destination = segue.destination as? FlightPlansListViewController,
           let flightPlansViewModel = viewModel.flightPlanListviewModel as? (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate) {
            flightPlansListViewController = destination
            viewModel.setToCompactMode()
            flightPlansListViewController?.setupViewModel(with: flightPlansViewModel)
        }
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension ManagePlansViewController {
    @IBAction func openButtonTouchedUpInside(_ sender: Any) {
        viewModel?.openSelectedFlightPlan()
    }

    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        viewModel?.closeManagePlans()
    }

    @IBAction func duplicateTouchUpInside(_ sender: Any) {
        viewModel?.duplicateSelectedFlightPlan()
    }

    @IBAction func deleteTouchUpInside(_ sender: Any) {
        viewModel.deleteFlightPlan()
    }

    @IBAction func newTouchUpInside(_ sender: Any) {
        viewModel?.newFlightPlan()
    }
}

// MARK: - Private Funcs
private extension ManagePlansViewController {

    /// Setup basic UI.
    func setupUI() {

        view.backgroundColor = ColorName.defaultBgcolor.color

        // Top Bar
        topBar.backgroundColor = ColorName.white.color
        topBar.layer.zPosition = 1
        topBar.addShadow()
        setupAccountView()

        /// Project name text field
        setupTextField()

        /// Buttons
        newButton.setup(title: L10n.flightPlanNew, style: .default2)
        duplicateButton.setup(title: L10n.flightPlanDuplicate, style: .default1)
        deleteButton.setup(title: L10n.commonDelete, style: .destructive)
        openButton.setup(title: L10n.flightPlanOpenLabel, style: .validate)
    }

    /// Setup Project name text field.
    func setupTextField() {
        nameTextField.makeUp(style: .largeMedium)
        nameTextField.textColor = ColorName.defaultTextColor.color
        nameTextField.backgroundColor = .clear
        nameTextField.text = nil
        nameTextField.returnKeyType = .done
        nameTextField.editingChangedPublisher
            .sink { [unowned self] in
                if $0.count > Constants.textFieldMaximumLength {
                    nameTextField.text = String($0.prefix(Constants.textFieldMaximumLength))
                }
            }
            .store(in: &cancellables)
        nameTextField.editingDidEndPublisher
            .sink { [unowned self] in
                nameTextField.resignFirstResponder()
                viewModel.renameSelectedFlightPlan(nameTextField.text)
            }
            .store(in: &cancellables)
        nameTextField.returnPressedPublisher
            .sink { [unowned self] in
                nameTextField.resignFirstResponder()
            }
            .store(in: &cancellables)

        nameTextField.rightView?.tapGesturePublisher
            .sink { [unowned self] _ in
                nameTextField.becomeFirstResponder()
            }
            .store(in: &cancellables)
    }

    private func bindViewModel() {
        viewModel.statePublisher
            .sink { [unowned self] state in
                var isEnabled: Bool
                switch state {
                case .none:
                    isEnabled = false
                    nameTextField.text = ""
                case .project(let flightPlan):
                    isEnabled = true
                    nameTextField.text = flightPlan.title
                }
                duplicateButton.isEnabled = isEnabled
                deleteButton.isEnabled = isEnabled
                openButton.isEnabled = isEnabled
                nameTextField.isEnabled = isEnabled
            }
            .store(in: &cancellables)
    }

    /// Setup account view.
    func setupAccountView() {
        if let currentAccount = AccountManager.shared.currentAccount,
           let viewAccount = currentAccount.myFlightsAccountView {
            viewAccount.translatesAutoresizingMaskIntoConstraints = false
            viewAccount.delegate = self
            view.addSubview(viewAccount)
            NSLayoutConstraint.activate([
                viewAccount.trailingAnchor.constraint(equalTo: topBar.layoutMarginsGuide.trailingAnchor,
                                                      constant: -Layout.mainPadding(isRegularSizeClass)),
                viewAccount.heightAnchor.constraint(equalToConstant: Constants.heightAccountView),
                viewAccount.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                viewAccount.leadingAnchor.constraint(equalTo: projectTitle.trailingAnchor)
            ])
            self.viewAccount = viewAccount
        }
    }

    /// Listen keyboard state (shown or hidden) changes.
    private func listenKeyboardPresentationChange() {
        keyboardPublisher
            .sink { [unowned self] in updateUIForKeyboardState($0) }
            .store(in: &cancellables)
    }

    /// Listen taps around the keyboard to simulate a 'Return' key pressed.
    private func returnsWhenTappedAroundKeyboard() {
        tapAroundKeyboardSubscriber = view.tapGesturePublisher
            .sink { [unowned self] in
                // Prevent to save changes when back button is tapped
                guard closeButton
                        .hitTest($0.location(in: view),
                                     with: nil) == nil
                else { return }
                // Hides the keyboard
                view.endEditing(true)
                // Save the current changes
                viewModel.renameSelectedFlightPlan(nameTextField.text)
            }
    }

    /// Disable action buttons and cells while keyboard is presented.
    ///
    ///  - parameters:
    ///   - state: the keyboard state.
    private func updateUIForKeyboardState(_ state: KeyboardState) {
        // Disable Buttons.
        openButton.isEnabled = state == .hidden
        duplicateButton.isEnabled = state == .hidden
        deleteButton.isEnabled = state == .hidden
        newButton.isEnabled = state == .hidden
        // Prevent to select another project.
        flightPlansListViewController?.view.isUserInteractionEnabled = state == .hidden
        // Handle taps around keyboard.
        if state == .shown {
            // Listen taps around the keyboard to dismiss it and save the project name.
            returnsWhenTappedAroundKeyboard()
        } else {
            // Cancel the view tap gesture subscriber.
            tapAroundKeyboardSubscriber?.cancel()
        }
    }
}

// MARK: - MyFlightsAccountViewDelegate
extension ManagePlansViewController: MyFlightsAccountViewDelegate {
    func didClickOnAccount() {
        coordinator?.startAccountView()
    }
}
