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

// MARK: - Protocols
/// Flight plan Edition menu delegate.
public protocol FlightPlanEditionMenuDelegate: class {
    /// Ends editing flight plan.
    func doneEdition()
    /// Undos action.
    func undoAction()
    /// Shows flight plan settings.
    func showSettings()
    /// Shows flight plan camera settings.
    func showImageSettings()
    /// Shows flight plan project manager.
    func showProjectManager()
    /// Shows flight plan history.
    func showHistory()
}

/// Flight plan's edition menu.
final class FlightPlanEditionMenuViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var doneButton: UIButton! {
        didSet {
            doneButton.makeup(with: .large, color: .greenSpring)
            doneButton.backgroundColor = ColorName.greenPea.color
            doneButton.applyCornerRadius(Style.largeCornerRadius)
            doneButton.setTitle(L10n.commonDone, for: .normal)
        }
    }
    @IBOutlet private weak var undoButton: UIButton! {
        didSet {
            undoButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                          radius: Style.largeCornerRadius)
        }
    }
    @IBOutlet private weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tableViewTrailingConstraint: NSLayoutConstraint!

    // MARK: - Public Properties
    public var flightPlanViewModel: FlightPlanViewModel? {
        didSet {
            tableView?.reloadData()
        }
    }
    public weak var delegate: FlightPlanEditionMenuDelegate?
    /// Provider used to get the settings of the flight plan provider.
    public var settingsProvider: FlightPlanSettingsProvider?

    // MARK: - Private Properties
    private var fpSettings: [FlightPlanSetting]? {
        if let flightPlan = flightPlanViewModel?.flightPlan,
           let settings = settingsProvider?.settings(for: flightPlan) {
            return settings
        } else {
            return settingsProvider?.settings
        }
    }
    private var trailingMargin: CGFloat {
        if UIApplication.shared.statusBarOrientation == .landscapeLeft {
            return UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
        } else {
            return 0.0
        }
    }

    // MARK: - Private Enums
    enum SectionsType: Int, CaseIterable {
        case project
        case image
        case settings
        case estimations
    }

    // MARK: - Private Enums
    private enum Constants {
        static let settingsCellheight: CGFloat = 80.0
        static let cellheight: CGFloat = 70.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupOrientationObserver()
        refreshContent()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    // MARK: - Public Funcs
    /// Refreshes table view data.
    public func refreshContent() {
        self.tableView.reloadData()
        undoButton.isEnabled = FlightPlanManager.shared.canUndo()
        undoButton.alphaWithEnabledState(undoButton.isEnabled)
    }

    /// Updates the top constraint of the tableview.
    ///
    /// - Parameters:
    ///     - value: contraint value
    public func updateTopTableViewConstraint(_ value: CGFloat) {
        self.tableViewTopConstraint.constant = value
    }
}

// MARK: - Actions
private extension FlightPlanEditionMenuViewController {
    @IBAction func doneTouchUpInside(_ sender: Any) {
        delegate?.doneEdition()
    }

    @IBAction func undoTouchUpInside(_ sender: Any) {
        delegate?.undoAction()
        refreshContent()
    }
}

// MARK: - Private Funcs
private extension FlightPlanEditionMenuViewController {
    /// Inits the view.
    func initView() {
        tableView.contentInsetAdjustmentBehavior = .always
        tableViewTrailingConstraint.constant = trailingMargin
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        tableView.register(cellType: SettingsMenuTableViewCell.self)
        tableView.register(cellType: ProjectMenuTableViewCell.self)
        tableView.register(cellType: EstimationsMenuTableViewCell.self)
        tableView.register(cellType: ImageMenuTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
    }

    /// Sets up observer for orientation change.
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateSafeAreaConstraints),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    /// Updates safe area constraints.
    @objc func updateSafeAreaConstraints() {
        tableViewTrailingConstraint.constant = trailingMargin
    }
}

// MARK: - UITableViewDataSource
extension FlightPlanEditionMenuViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionsType.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = SectionsType(rawValue: indexPath.section)
        switch type {
        case .settings:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsMenuTableViewCell
            cell.setup(settings: fpSettings ?? [])
            return cell
        case .image:
            return tableView.dequeueReusableCell(for: indexPath) as ImageMenuTableViewCell
        case .project:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ProjectMenuTableViewCell
            cell.setup(name: flightPlanViewModel?.state.value.title,
                       hasHistory: flightPlanViewModel?.executions.isEmpty == false,
                       delegate: self)
            return cell
        case .estimations:
            let cell = tableView.dequeueReusableCell(for: indexPath) as EstimationsMenuTableViewCell
            let estimations = flightPlanViewModel?.estimations ?? FlightPlanEstimationsModel()
            cell.setup(estimations: estimations)
            return cell
        default:
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension FlightPlanEditionMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let type = SectionsType(rawValue: indexPath.section)
        switch type {
        case .settings:
            delegate?.showSettings()
        case .image:
            delegate?.showImageSettings()
        case .project:
            delegate?.showProjectManager()
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = SectionsType(rawValue: indexPath.section)
        switch type {
        case .settings:
            return Constants.settingsCellheight
        default:
            return Constants.cellheight
        }
    }
}

// MARK: - ProjectMenuTableViewCellDelegate
extension FlightPlanEditionMenuViewController: ProjectMenuTableViewCellDelegate {
    func didSelectHistory() {
        self.delegate?.showHistory()
    }
}
