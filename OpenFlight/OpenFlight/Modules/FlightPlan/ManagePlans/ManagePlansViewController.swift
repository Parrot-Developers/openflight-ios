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
import Combine

/// Manages flight plan managing view.
final class ManagePlansViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var topView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var projectTitle: UILabel! {
        didSet {
            projectTitle.makeUp(with: .largeMedium)
            projectTitle.text = L10n.flightPlanProjects
        }
    }
    @IBOutlet private weak var currentProjectView: UIView!
    @IBOutlet private weak var openRecentView: UIView!
    @IBOutlet private weak var projectName: UILabel! {
        didSet {
            projectName.makeUp(with: .small, and: .white80)
            projectName.text = L10n.flightPlanProjectName.uppercased()
        }
    }
    @IBOutlet private weak var textfield: UITextField! {
        didSet {
            textfield.makeUp(style: .largeMedium)
            textfield.backgroundColor = .clear
        }
    }
    @IBOutlet private weak var duplicateButton: UIButton! {
        didSet {
            duplicateButton.makeup()
            duplicateButton.makeup(with: .regular, color: .white50, and: .disabled)
            duplicateButton.applyCornerRadius(Style.largeCornerRadius)
            duplicateButton.backgroundColor = ColorName.white20.color
            duplicateButton.setTitle(L10n.flightPlanDuplicate, for: .normal)
        }
    }
    @IBOutlet private weak var deleteButton: UIButton! {
        didSet {
            deleteButton.makeup()
            deleteButton.applyCornerRadius(Style.largeCornerRadius)
            deleteButton.backgroundColor = ColorName.redTorch50.color
            deleteButton.tintColor = ColorName.white.color
            deleteButton.setTitle(L10n.commonDelete, for: .normal)
        }
    }
    @IBOutlet private weak var newButton: UIButton! {
        didSet {
            newButton.makeup(color: .greenSpring)
            newButton.applyCornerRadius(Style.largeCornerRadius)
            newButton.backgroundColor = ColorName.greenSpring20.color
            newButton.setTitle(L10n.flightPlanNew, for: .normal)
        }
    }
    @IBOutlet private weak var openButton: UIButton! {
        didSet {
            openButton.makeup()
            openButton.cornerRadiusedWith(backgroundColor: ColorName.white50.color,
                                          radius: Style.largeCornerRadius)
            openButton.setTitle(L10n.flightPlanOpenLabel, for: .normal)
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let textFieldMaximumLength: Int = 50
    }

    // MARK: - Private properties
    private var viewModel: ManagePlansViewModelInput!
    private var cancellables = [AnyCancellable]()
    private(set) weak var flightPlansListViewController: FlightPlansListViewController?

    // MARK: - Setup
    static func instantiate(viewModel: ManagePlansViewModel) -> ManagePlansViewController {
        let viewController = StoryboardScene.ManagePlans.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Private Funcs
    private func bindViewModel() {
        viewModel.statePublisher
            .sink { [unowned self] state in
                var isEnabled: Bool
                switch state {
                case .noFlightPlan:
                    isEnabled = false
                    textfield.text = ""
                case .flightPlan(let flightPlan):
                    isEnabled = true
                    textfield.text = flightPlan.state.value.title
                }
                duplicateButton.isEnabled = isEnabled
                deleteButton.isEnabled = isEnabled
                openButton.isEnabled = isEnabled
                textfield.isEnabled = isEnabled
            }
            .store(in: &cancellables)

        viewModel.resetTitlePublisher
            .sink { [unowned self] text in
                textfield.text = text
            }
            .store(in: &cancellables)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup view.
        currentProjectView.addBlurEffect(with: .dark, cornerRadius: 0.0)
        // Setup textfield.
        textfield.text = nil
        textfield.delegate = self
        bindViewModel() 
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.flightPlanManageDialog,
                             logType: .screen)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let destination = segue.destination as? FlightPlansListViewController,
           let flightPlansViewModel = self.viewModel.flightPlanListviewModel as? (FlightPlansListViewModelUIInput & FlightPlanListHeaderDelegate) {
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
        viewModel?.deleteSelectedFlightPlan()
    }

    @IBAction func newTouchUpInside(_ sender: Any) {
        viewModel?.newFlightPlan()
    }
}

// MARK: - UITextField Delegate
extension ManagePlansViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let name = textField.text, !name.isEmpty {
            viewModel?.renameSelectedFlightPlan(name)
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        if substringToReplace.count > string.count {
            // Always allow removing characters.
            return true
        } else {
            let count = textFieldText.count - substringToReplace.count + string.count
            return count <= Constants.textFieldMaximumLength
        }
    }
}
