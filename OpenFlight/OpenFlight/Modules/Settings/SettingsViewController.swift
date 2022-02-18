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

/// Settings entry point view controller.
/// Contains and manages the 3 settings panels (quick, controls and advanced).
/// Advanced settings use a TableView to plit settings in section.
/// Actual settings are embeded in a containerView and can be switched regarding panel and/or section.
final class SettingsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var leftPanelContainerView: UIView!
    @IBOutlet private weak var sectionsTableView: UITableView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var segmentedControl: SettingsSegmentedControl!

    // MARK: - Private Properties
    private var selectedSection: SettingsType = SettingsType.defaultType
    private var selectedPanel: SettingsPanelType = SettingsPanelType.defaultPanel
    private weak var coordinator: SettingsCoordinator?
    fileprivate var sections = [SettingsType]()

    // MARK: - Init
    /// init view controller with coordinator and settings type
    ///
    /// - Parameters:
    ///    - coordinator: settings coordinator
    ///    - settingType: if settingType is not nil, the related settings will be presented on launch
    static func instantiate(coordinator: SettingsCoordinator, settingType: SettingsType?) -> SettingsViewController {
        let viewController = StoryboardScene.Settings.initialScene.instantiate()
        viewController.coordinator = coordinator
        if let settingType = settingType {
            viewController.selectedSection = settingType
        }

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.settings))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        sectionsTableView.flashScrollIndicators()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension SettingsViewController {
    /// Close button clicked.
    @IBAction func closeButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyCommonButton.back))
        coordinator?.dismissSettings()
    }
}

// MARK: - Private Funcs
private extension SettingsViewController {

    /// Initializes view controller
    func initView() {
        sectionsTableView.rowHeight = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        sectionsTableView.register(cellType: SettingsSectionCell.self)

        setupSegmentedControl()
        reloadPanelContent(settingsType: selectedSection)
    }

    /// Setup segmented control
    func setupSegmentedControl() {
        let segments = SettingsPanelType.allCases.map { SettingsSegment(title: $0.title, disabled: false, image: nil) }
        segmentedControl.delegate = self
        segmentedControl.segmentModel = SettingsSegmentModel(segments: segments,
                                                             selectedIndex: SettingsPanelType.type(for: selectedSection).index,
                                                             isBoolean: false)

        select(panel: SettingsPanelType.type(for: selectedSection), settings: selectedSection)
    }

    /// Reload panel content.
    ///
    /// - Parameters:
    ///    - settingsType: specify content type to display.
    func reloadPanelContent(settingsType: SettingsType? = nil) {
        // Update selected section if defined (advanced segment has multiple sections).
        selectedSection = settingsType ?? selectedPanel.defaultSettings
        reloadTableViewSections()
        reloadContainerView()
    }

    /// Reload TableView sections.
    func reloadTableViewSections() {
        sections = selectedPanel.settingsTypes
        sectionsTableView?.reloadData()
    }

    /// Select a panel and a section
    ///
    /// - Parameters:
    ///    - panel: panel to select.
    ///    - settings: settings to display.
    func select(panel: SettingsPanelType, settings: SettingsType? = nil) {
        selectedPanel = panel
        reloadPanelContent(settingsType: settings)
    }

    /// Reload container view.
    func reloadContainerView() {
        let controller: UIViewController

        switch selectedSection {
        case .interface:
            controller = StoryboardScene.SettingsInterfaceViewController.initialScene.instantiate()
        case .quick:
            controller = StoryboardScene.SettingsQuickViewController.initialScene.instantiate()
        case .behaviour:
            controller = StoryboardScene.BehavioursViewController.initialScene.instantiate()
        case .camera:
            controller = StoryboardScene.SettingsCameraViewController.initialScene.instantiate()
        case .rth:
            controller = StoryboardScene.SettingsRTHViewController.initialScene.instantiate()
        case .controls:
            controller = StoryboardScene.SettingsControlsViewController.initialScene.instantiate()
        case .geofence:
            controller = StoryboardScene.SettingsGeofenceViewController.initialScene.instantiate()
        case .network:
            controller = StoryboardScene.SettingsNetworkViewController.initialScene.instantiate()
        }

        if let controller = controller as? SettingsContentViewController {
            controller.coordinator = coordinator
        }

        cleanContainerContent()

        addChild(controller)
        containerView.addWithConstraints(subview: controller.view)
        controller.didMove(toParent: self)
    }

    /// Refresh setting content.
    ///
    /// - Parameters:
    ///    - state: device connection state.
    func refreshContent(_ state: DeviceConnectionState) {
        if state.isConnected() {
            // Update content but keep current selected section.
            reloadPanelContent(settingsType: selectedSection)
        }
    }

    /// Clean content by removing all container views.
    func cleanContainerContent() {
        for view in containerView.subviews {
            view.removeFromSuperview()
        }
        for childVC in children {
            childVC.removeFromParent()
        }
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        leftPanelContainerView.isHidden = sections.count <= 1
        return sections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as SettingsSectionCell
        let section: SettingsType = sections[indexPath.row]
        cell.configure(with: section.settingSection)
        cell.selectCell((selectedSection == section))

        return cell
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSection = sections[indexPath.row]
        reloadContainerView()

        let oldCurrentScrollPosition = tableView.contentOffset.y
        tableView.reloadData()

        if oldCurrentScrollPosition != tableView.contentOffset.y {
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
}

// MARK: - SettingsSegmentedControlDelegate
extension SettingsViewController: SettingsSegmentedControlDelegate {
    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl, selectedSegmentIndex: Int) {
        select(panel: SettingsPanelType.type(at: selectedSegmentIndex))
    }
}
