//
//
//  Copyright (C) 2021 Parrot Drones SAS.
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
    @IBOutlet private weak var topBar: UIView!

    /// Right pane
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var duplicateButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var textFieldUnderline: UIView!

    /// Projects list view
    @IBOutlet private weak var projectsListView: UIView!

    // MARK: - Private Properties
    private var viewAccount: MyFlightsAccountView?
    private var coordinator: DashboardCoordinator?
    private var viewModel: ProjectManagerViewModel!
    private(set) weak var projectsListViewController: ProjectsListViewController?
    private var selectedType: ProjectManagerUiParameters.ProjectType? {
          viewModel.projectType(for: segmentedControl?.selectedSegmentIndex)
    }
    private var selectedProject: ProjectModel? {
        projectsListViewController?.viewModel.selectedProject
    }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let heightAccountView: CGFloat = 40
        static let trailingAccountView: CGFloat = -20
        static let textFieldMaximumLength: Int = 50
        static let buttonBorderColorAlpha: CGFloat = 0.32
        static let buttonBorderWidth: CGFloat = 1
   }

    // MARK: - Setup
    static func instantiate(coordinator: DashboardCoordinator,
                            viewModel: ProjectManagerViewModel) -> ProjectManagerViewController {
        let viewController = StoryboardScene.ProjectManager.projectManagerViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        initUI()
        bindViewModel()
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension ProjectManagerViewController {

    /// Top bar actions
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.back()
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
        viewModel.shhowDeletionConfirmation(for: selectedProject)
    }

    @IBAction func newButtonDidTap(_ sender: Any) {
        guard let flightPlanProvider = selectedType?.flightPlanProvider else { return }
        viewModel.createNewProject(for: flightPlanProvider)
    }
}

// MARK: - Private Funcs
private extension ProjectManagerViewController {

    enum ButtonStyle {
        case `default`, new, delete
    }

    /// Instantiate basic UI.
    func initUI() {
        /// Top Bar
        topBar.addLightShadow()
        setupSegmentedControl()
        setupAccountView()

        /// Right pane
        setupTextField()

        initUIButton(openButton, .default, L10n.flightPlanOpenLabel)
        initUIButton(duplicateButton, .default, L10n.flightPlanDuplicate)
        initUIButton(deleteButton, .delete, L10n.commonDelete)
        initUIButton(newButton, .new, L10n.flightPlanNew)
    }

    func initUIButton(_ button: UIButton, _ style: ButtonStyle, _ title: String) {
        var titleColor = ColorName.defaultTextColor
        var disabledTitleColor = ColorName.defaultTextColor80
        var backgroundColor = ColorName.white.color

        switch style {
        case .default:
            titleColor = ColorName.defaultTextColor
            disabledTitleColor = ColorName.defaultTextColor80
            backgroundColor = ColorName.white.color
        case .new:
            titleColor = ColorName.white
            disabledTitleColor = ColorName.white50
            backgroundColor = ColorName.highlightColor.color
        case .delete:
            titleColor = ColorName.white
            disabledTitleColor = ColorName.white50
            backgroundColor = ColorName.errorColor.color
        }

        button.makeup()
        button.makeup(color: titleColor)
        button.makeup(color: disabledTitleColor, and: .disabled)
        button.applyCornerRadius(Style.largeCornerRadius)
        button.backgroundColor = backgroundColor
        button.setTitle(title, for: .normal)
        button.addLightShadow(condition: button.isEnabled)

        if style == .default {
            button.layer.borderWidth = Constants.buttonBorderWidth
            button.layer.borderColor = ColorName.disabledTextColor.color
                .withAlphaComponent(Constants.buttonBorderColorAlpha)
                .cgColor
        }

        button.publisher(for: \.isEnabled)
            .sink { isEnabled in
                button.alphaWithEnabledState(isEnabled)
                button.addLightShadow(condition: isEnabled)
          }
            .store(in: &cancellables)
    }

    /// Setup account view.
    func setupAccountView() {
        if let currentAccount = AccountManager.shared.currentAccount,
           let viewAccount = currentAccount.myFlightsAccountView {
            viewAccount.delegate = self
            viewAccount.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(viewAccount)
            NSLayoutConstraint.activate([
                viewAccount.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: Constants.trailingAccountView),
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
        segmentedControl.selectedSegmentIndex = viewModel.index(of: selectedType) ?? 0
        segmentedControl.customMakeup()
    }

    /// Setup Project name text field.
    func setupTextField() {
        nameTextField.makeUp(style: .largeMedium)
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
                guard let selectedProject = selectedProject else { return }
                viewModel.renameProject(selectedProject,
                                                with: nameTextField.text)
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
}

// MARK: - MyFlightsAccountViewDelegate
extension ProjectManagerViewController: MyFlightsAccountViewDelegate {
    func didClickOnAccount() {
        coordinator?.startMyFlightsAccountView()
    }
}
