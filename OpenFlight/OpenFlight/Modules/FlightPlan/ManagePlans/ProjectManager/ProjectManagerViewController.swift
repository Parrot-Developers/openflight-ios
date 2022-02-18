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
import Combine

/// Project Manager View Conttroler
class ProjectManagerViewController: UIViewController {
    // MARK: - Outlets
    /// Top Bar
    @IBOutlet private weak var segmentedControl: UISegmentedControl!
    @IBOutlet private weak var topBar: UIStackView!

    /// Right pane
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var openButton: ActionButton!
    @IBOutlet weak var duplicateButton: ActionButton!
    @IBOutlet weak var deleteButton: ActionButton!
    @IBOutlet weak var newButton: ActionButton!
    @IBOutlet weak var textFieldUnderline: UIView!

    // MARK: - Private Properties
    private var viewAccount: MyFlightsAccountView?
    private var coordinator: ProjectManagerCoordinator?
    private var viewModel: ProjectManagerViewModel!
    private(set) weak var projectsListViewController: ProjectsListViewController?
    private var selectedType: ProjectManagerUiParameters.ProjectType? {
          viewModel.projectType(for: segmentedControl?.selectedSegmentIndex)
    }
    private var selectedProject: ProjectModel? {
        projectsListViewController?.viewModel.selectedProject
    }
    private var cancellables = Set<AnyCancellable>()
    private var tapAroundKeyboardSubscriber: AnyCancellable?

    private var defaultSelectedProject: ProjectModel?

    // MARK: - Private Enums
    private enum Constants {
        static let heightAccountView: CGFloat = 40
        static let trailingAccountView: CGFloat = -20
        static let textFieldMaximumLength: Int = 50
   }

    // MARK: - Setup
    static func instantiate(coordinator: ProjectManagerCoordinator,
                            viewModel: ProjectManagerViewModel,
                            defaultSelectedProject: ProjectModel? = nil) -> ProjectManagerViewController {
        let viewController = StoryboardScene.ProjectManager.projectManagerViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.defaultSelectedProject = defaultSelectedProject
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        initUI()
        bindViewModel()
        updateUIForDefaultSelectedProject()
        listenKeyboardPresentationChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewAccount?.viewWillAppear()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let destination = segue.destination as? ProjectsListViewController {
            destination.setupViewModel(ProjectsListViewModel(coordinator: coordinator,
                                                             manager: viewModel.manager,
                                                             cloudSynchroWatcher: viewModel.cloudSynchroWatcher,
                                                             projectManagerViewModel: viewModel))
            projectsListViewController = destination
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
private extension ProjectManagerViewController {

    /// Top bar actions
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.dismissProjectManager()
    }

    @IBAction func segmentDidChange(_ sender: Any) {
        guard let selectedType = selectedType else { return }
        viewModel.updateProjectType(selectedType)
    }

    /// Right pane actions
    @IBAction func openButtonDidTap(_ sender: Any) {
        guard let selectedProject = selectedProject else { return }
        viewModel.openProject(selectedProject)
    }

    @IBAction func duplicateButtonDidTap(_ sender: Any) {
        guard let selectedProject = selectedProject else { return }
        viewModel.duplicateProject(selectedProject)
    }

    @IBAction func deleteButtonDidTap(_ sender: Any) {
        guard let selectedProject = selectedProject else { return }
        viewModel.showDeletionConfirmation(for: selectedProject)
    }

    @IBAction func newButtonDidTap(_ sender: Any) {
        guard let flightPlanProvider = selectedType?.flightPlanProvider else { return }
        viewModel.createNewProject(for: flightPlanProvider)
    }
}

// MARK: - Private Funcs
private extension ProjectManagerViewController {

    /// Instantiate basic UI.
    func initUI() {
        /// Top Bar
        setupSegmentedControl()
        setupAccountView()

        /// Right pane
        setupTextField()

        newButton.setup(title: L10n.flightPlanNew, style: .default2)
        duplicateButton.setup(title: L10n.flightPlanDuplicate, style: .default1)
        deleteButton.setup(title: L10n.commonDelete, style: .destructive)
        openButton.setup(title: L10n.flightPlanOpenLabel, style: .validate)
        textFieldUnderline.backgroundColor = ColorName.separator.color
    }

    /// Setup account view.
    func setupAccountView() {
        if let currentAccount = AccountManager.shared.currentAccount,
           let viewAccount = currentAccount.myFlightsAccountView {
            viewAccount.delegate = self
            viewAccount.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(viewAccount)
            NSLayoutConstraint.activate([
                viewAccount.trailingAnchor.constraint(equalTo: topBar.layoutMarginsGuide.trailingAnchor,
                                                      constant: -Layout.mainPadding(isRegularSizeClass)),
                viewAccount.heightAnchor.constraint(equalToConstant: Constants.heightAccountView),
                viewAccount.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
                viewAccount.leadingAnchor.constraint(equalTo: segmentedControl.trailingAnchor)
            ])
            self.viewAccount = viewAccount
        }
    }

    /// Setup segmented control.
    func setupSegmentedControl() {
        segmentedControl.removeAllSegments()
        for projectType in viewModel.projectTypes {
            segmentedControl.insertSegment(withTitle: projectType.title?.capitalized,
                                           at: segmentedControl.numberOfSegments,
                                           animated: false)
        }
        segmentedControl.selectedSegmentIndex = viewModel.segmentedControlSelectedIndex
        segmentedControl.customMakeup()
    }

    /// Setup Project name text field.
    func setupTextField() {
        nameTextField.makeUp(style: .largeMedium)
        nameTextField.returnKeyType = .done
        nameTextField.textColor = ColorName.defaultTextColor.color
        nameTextField.backgroundColor = .clear
        nameTextField.text = nil
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
            }
            .store(in: &cancellables)
        nameTextField.returnPressedPublisher
            .sink { [unowned self] in
                nameTextField.resignFirstResponder()
                guard let selectedProject = selectedProject else { return }
                viewModel.renameProject(selectedProject,
                                                with: nameTextField.text)
            }
            .store(in: &cancellables)

        nameTextField.rightView?.tapGesturePublisher
            .sink { [unowned self] _ in
                nameTextField.becomeFirstResponder()
            }
            .store(in: &cancellables)
    }

    private func bindViewModel() {
        projectsListViewController?.viewModel.$selectedProject
            .sink { [unowned self] selectedProject in
                nameTextField.resignFirstResponder()
                duplicateButton.isEnabled = selectedProject != nil
                deleteButton.isEnabled =  selectedProject != nil
                openButton.isEnabled =  selectedProject != nil
                nameTextField.isEnabled =  selectedProject != nil
                nameTextField.text = selectedProject != nil ? selectedProject?.title : nil
                nameTextField.alpha =  selectedProject != nil ? 1 : 0
                textFieldUnderline.alpha = nameTextField.alpha
                if let selectedProject = selectedProject {
                    deleteButton.isEnabled =  viewModel?.canDeleteProject(selectedProject) ?? true
                }
             }
            .store(in: &cancellables)
    }

    private func updateUIForDefaultSelectedProject() {
        guard let defaultSelectedProject = defaultSelectedProject else { return }
        segmentedControl.selectedSegmentIndex = viewModel.projectTypeIndex(of: defaultSelectedProject) ?? 0
        if let selectedType = selectedType { viewModel.updateProjectType(selectedType) }
        projectsListViewController?.viewModel.didSelect(project: defaultSelectedProject)
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
                // Prevent to save changes when top bar (back button) is tapped
                guard topBar
                        .hitTest($0.location(in: view),
                                     with: nil) == nil
                else { return }
                // Hides the keyboard
                view.endEditing(true)
                // Save the current changes
                guard let selectedProject = selectedProject else { return }
                viewModel.renameProject(selectedProject,
                                                with: nameTextField.text)
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
        projectsListViewController?.view.isUserInteractionEnabled = state == .hidden
        // Prevent to switch to another project type.
        segmentedControl.isUserInteractionEnabled = state == .hidden
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
extension ProjectManagerViewController: MyFlightsAccountViewDelegate {
    func didClickOnAccount() {
        coordinator?.startAccountView()
    }
}
