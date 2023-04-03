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

// MARK: - Protocols
/// Flight plan Edition menu delegate.
public protocol FlightPlanEditionMenuDelegate: AnyObject {
    /// Ends editing flight plan.
    func doneEdition(_ flightPlan: FlightPlanModel)
    /// Undos action.
    func undoAction()
    /// Shows flight plan settings.
    ///
    /// - Parameters
    ///     - category: setting category
    func showSettings(category: FlightPlanSettingCategory)
    /// Shows flight plan project manager.
    func showProjectManager()
    /// Resets undo stack
    func resetUndoStack()
}

/// Flight plan's edition menu.
final class FlightPlanEditionMenuViewController: UIViewController {
    weak var coordinator: Coordinator?
    // MARK: - IBOutlets
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var topBarContainer: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var doneButton: ActionButton!
    @IBOutlet private weak var undoButton: ActionButton!
    @IBOutlet private weak var bottomGradientView: BottomGradientView!
    @IBOutlet private weak var buttonsStackView: MainContainerStackView!

    // MARK: - Public Properties
    var viewModel: FlightPlanEditionMenuViewModel!
    private var cancellables = [AnyCancellable]()

    public weak var menuDelegate: FlightPlanEditionMenuDelegate?
    public weak var settingsDelegate: EditionSettingsDelegate?
    /// Provider used to get the settings of the flight plan provider.
    public var settingsProvider: FlightPlanSettingsProvider?
    private var flightPlan: FlightPlanModel?
    private var topbar: FlightPlanTopBarViewController?

    // MARK: - Private Properties
    private var fpSettings: [FlightPlanSetting]? {
        if let flightPlan = flightPlan,
           let settings = settingsProvider?.settings(for: flightPlan) {
            return settings
        } else {
            return settingsProvider?.settings
        }
    }

    /// Build data source regarding setting categories.
    private var dataSource: [SectionsType] {
        let categories = settingsProvider?.settingsCategories
        var sections: [SectionsType] = [
            .projectName
        ]
        if settingsProvider?.hasCustomType == true {
            // Optional section mode.
            sections.append(.mode)
        }
        if categories?.contains(.image) == true {
            // Image has it own section.
            sections.append(.image)
        }
        if let categories = categories?.filter({ $0 != .image}) {
            categories.forEach { category in
                // displatch categories in dedicated sections.
                if fpSettings?.contains(where: { $0.category == category }) == true {
                    sections.append(.settings(category))
                }
            }
        } else {
            sections.append(.settings(.common))
        }
        sections.append(.estimation)
        return sections
    }

    // MARK: - Private Enums
    private enum SectionsType {
        case project
        case projectName
        case mode
        case image
        case settings(FlightPlanSettingCategory)
        case estimation

        var title: String {
            switch self {
            case .projectName:
                return L10n.flightPlanProjectName
            case .project:
                return L10n.flightPlanMenuProject.uppercased()
            case .mode:
                return L10n.commonMode.uppercased()
            case .image:
                return L10n.flightPlanMenuImage.uppercased()
            case .settings(let category):
                return category.title.uppercased()
            case .estimation:
                return L10n.flightPlanEstimations.uppercased()
            }
        }
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        refreshContent()
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.$viewState
            .compactMap({ $0 })
            .sink { [unowned self] state in
                switch state {
                case let .update(flighPlan):
                    self.flightPlan = flighPlan
                    self.tableView?.reloadData()
                case .refresh:
                    self.refreshContent()
                }
            }
            .store(in: &cancellables)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Private Funcs
    /// Refreshes view data.
    private func refreshContent() {
        self.tableView.reloadData()
        if let canUndo = settingsDelegate?.canUndo() {
            undoButton.isEnabled = canUndo
            if canUndo {
                bottomGradientView.shortGradient()
            } else {
                bottomGradientView.mediumGradient()
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "topBarSegue" {
            topbar = segue.destination as? FlightPlanTopBarViewController
        }
    }
}

// MARK: - Actions
private extension FlightPlanEditionMenuViewController {
    @IBAction func doneTouchUpInside(_ sender: Any) {
        guard let flightPlan = flightPlan else { return }
        menuDelegate?.doneEdition(flightPlan)
    }

    @IBAction func undoTouchUpInside(_ sender: Any) {
        menuDelegate?.undoAction()
        refreshContent()
    }
}

// MARK: - Private Funcs
private extension FlightPlanEditionMenuViewController {
    /// Inits the view.
    func initView() {
        tableView.insetsContentViewsToSafeArea = false // Safe area is handled in this VC, not in content
        tableView.register(cellType: SettingsMenuTableViewCell.self)
        tableView.register(cellType: EstimationMenuTableViewCell.self)
        tableView.register(cellType: ProjectMenuTableViewCell.self)
        tableView.register(cellType: ProjectNameMenuTableViewCell.self)
        tableView.register(cellType: ImageMenuTableViewCell.self)
        tableView.register(cellType: ModesChoiceTableViewCell.self)
        tableView.register(headerFooterViewType: HeaderMenuTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = CGFloat.leastNonzeroMagnitude
        tableView.sectionFooterHeight = CGFloat.leastNonzeroMagnitude
        tableView.contentInset.top = Layout.mainPadding(isRegularSizeClass)
        tableView.contentInset.bottom = Layout.mainContainerInnerMargins(isRegularSizeClass).bottom +
        Layout.mainPadding(isRegularSizeClass) +
        Layout.buttonIntrinsicHeight(isRegularSizeClass)
        tableView.makeUp(backgroundColor: .clear)

        undoButton.setup(image: Asset.Common.Icons.icUndo.image, style: .default2)
        doneButton.setup(title: L10n.commonDone, style: .validate)

        buttonsStackView.screenBorders = [.bottom, .right]
        topbar?.set(projectTitle: flightPlan?.pictorModel.name)
        if !dataSource.isEmpty {
            let type = dataSource[0]
            topbar?.set(title: type.title)
        }

        // Keeps the topBar shadow above the tableView
        stackView.bringSubviewToFront(topBarContainer)
        topBarContainer.isHidden = true
    }
}

// MARK: - UITableViewDataSource
extension FlightPlanEditionMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let type = dataSource[section]
        switch type {
        case .settings(let category):
            return fpSettings?.filter({ $0.category == category })
                .filter(for: flightPlan) // Filter settings which are not available for imported mavlink.
                .count ?? 0
        case .mode,
             .image,
             .project,
             .projectName,
             .estimation:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = dataSource[indexPath.section]
        switch type {
        case .settings(let category):
            let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsMenuTableViewCell
            let customRth = flightPlan?.dataSetting?.customRth == true
            let isEditable = isEditableSettingCategory(category)
            if let categorizedSettings = fpSettings?.filter({ $0.category == category }) {
                // Filter settings which are not available for imported mavlink.
                let filteredSettings = categorizedSettings.filter(for: flightPlan)
                let setting = filteredSettings[indexPath.row]
                cell.setup(setting: setting,
                           index: indexPath.row,
                           numberOfRows: tableView.numberOfRows(inSection: indexPath.section),
                           isEditable: isEditable,
                           inEditionMode: true,
                           customRth: customRth)
            }
            return cell
        case .image:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ImageMenuTableViewCell
            let cellProvider = ImageMenuCellProvider(dataSettings: flightPlan?.dataSetting)
            cell.setup(provider: cellProvider,
                       settings: fpSettings?.filter({ $0.category == .image }) ?? [])
            return cell
        case .mode:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ModesChoiceTableViewCell
            cell.fill(with: settingsProvider)
            cell.delegate = self
            return cell
        case .project:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ProjectMenuTableViewCell
            cell.setup(with: viewModel.projectNameCellProvider(forFlightPlan: flightPlan))
            return cell
        case .projectName:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ProjectNameMenuTableViewCell
            cell.setup(with: viewModel.projectNameCellProvider(forFlightPlan: flightPlan))
            return cell
        case .estimation:
            let cell = tableView.dequeueReusableCell(for: indexPath) as EstimationMenuTableViewCell
            cell.updateEstimations(estimationModel: flightPlan?.dataSetting?.estimations)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension FlightPlanEditionMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // Force `endEditing` in order to dismiss keyboard whenever a new panel is shown
        // in order to avoid UI textField selection glitch.
        view.endEditing(true)

        let type = dataSource[indexPath.section]
        switch type {
        case .settings(let category):
            guard isEditableSettingCategory(category) else { return }
            menuDelegate?.showSettings(category: category)
        case .image:
            menuDelegate?.showSettings(category: .image)
        case .project:
            menuDelegate?.showProjectManager()
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let type = dataSource[section]
        switch type {
        case .project, .projectName:
            return UIView(frame: CGRect.zero)
        case .mode:
            let view = tableView.dequeueReusableHeaderFooterView(HeaderMenuTableViewCell.self)
            view?.setup(with: nil)
            return view
        default:
            let view = tableView.dequeueReusableHeaderFooterView(HeaderMenuTableViewCell.self)
            view?.setup(with: type.title) { [unowned self] in
                sectionHeaderTapped(section)
            }
            return view
        }
    }

    /// Emulates a tap on the first cell of a section when a header of section is tapped
    ///
    /// - Parameters:
    ///   - section: the section that was tapped
    @objc func sectionHeaderTapped(_ section: Int) {
        let indexPath = IndexPath(row: 0, section: section)
        tableView(tableView, didSelectRowAt: indexPath)

    }
}

// MARK: - ModesChoiceTableViewCell
extension FlightPlanEditionMenuViewController: ModesChoiceTableViewCellDelegate {
    func updateMode(tag: Int) {
        settingsDelegate?.updateMode(tag: tag)
    }
}

// MARK: - Private methods
extension FlightPlanEditionMenuViewController {
    /// Returns the editable state of a setting category.
    ///
    /// - Parameter category: the category
    /// - Returns: `true` if category settings can be edited, `false` otherwise
    func isEditableSettingCategory(_ category: FlightPlanSettingCategory) -> Bool {
        // Altitude reference category settings can't be edited.
        if category == .altitudeRef { return false }
        // All other categories, except the custom RTH, are always editable.
        if category != .rth { return true }
        // Custom RTH can be edited depending the selected mission setting.
        return flightPlan?.dataSetting?.customRth == true
    }
}
