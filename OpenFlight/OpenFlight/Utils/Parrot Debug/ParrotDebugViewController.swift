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

import SwiftyUserDefaults
import GroundSdk
import Combine
import CoreGraphics

private extension ULogTag {
    static let tag = ULogTag(name: "ParrotDebugViewController")
}

/// Parrot Debug screen to activate, edit & share logs.
public class ParrotDebugViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var informationsLabel: UILabel!
    @IBOutlet private weak var activateLogsLabel: UILabel!
    @IBOutlet private weak var logLevelLabel: UILabel!
    @IBOutlet private weak var filesTableView: UITableView!
    @IBOutlet private weak var switchLog: UISwitch!
    @IBOutlet private weak var logLevelSwitch: UISwitch!
    @IBOutlet private weak var enableStreamRecord: UIButton!
    @IBOutlet private weak var sendDebugTagButton: UIButton!
    @IBOutlet private weak var sendDebugTagTextField: POFTextField!
    @IBOutlet private weak var customMissionButton: UIButton!
    @IBOutlet private weak var exportFlightPlanFilesButton: UIButton!

    // MARK: - Private Properties
    private var drone: Drone?
    private weak var renameOkAction: UIAlertAction?
    private var nameToRename: String?
    private var documentInteractionController: UIDocumentInteractionController!
    private var fileListUrls = [URL]()
    private var currentLogDirectory: String? { ParrotDebug.currentLogDirectory?.lastPathComponent }
    private var refreshControl = UIRefreshControl()
    private weak var coordinator: ParrotDebugCoordinator?
    private var viewModel: ParrotDebugProvider!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let fileCellRowHeight: CGFloat = 40.0
        static let usCountryCode = "US"
        static let defaultShareUti = "public.data, public.content"
        static let bundleVersionKey = "CFBundleVersion"
        static let oaRecordStartConfName = "oarecord_start"
    }

    // MARK: - Init
    public static func instantiate(coordinator: ParrotDebugCoordinator, viewModel: ParrotDebugProvider) -> ParrotDebugViewController {
        let viewController = StoryboardScene.ParrotDebug.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        activateLogsLabel.text = L10n.debugLogActivateLog

        filesTableView.delegate = self
        filesTableView.dataSource = self
        filesTableView.rowHeight = Constants.fileCellRowHeight
        filesTableView.tableFooterView = UIView()
        filesTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshFileList(_:)), for: .valueChanged)
        sendDebugTagTextField.setPlaceholderTitle("Debug tag...")

        Services.hub.currentDroneHolder.dronePublisher
            .sink { [weak self] drone in
                self?.drone = drone
            }
            .store(in: &cancellables)

        viewModel.shouldShowCustomMissionButton
            .removeDuplicates()
            .sink { [weak self] shouldShow in
                guard let self = self else { return }
                self.customMissionButton.isHidden = !shouldShow
            }
            .store(in: &cancellables)
    }

    public override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

        switchLog.isOn = ParrotDebugViewController.isLogActive()
        logLevelSwitch.isOn = !AppUtils.isLogLevelInfo()
        // disable access to the switch currently - TFF7-1028
        logLevelSwitch.isEnabled = false
        loadFileList()
        displayInformations()
        updateStreamRecordDisplay()
        LogEvent.log(.screen(LogEvent.Screen.debugLogs))
        exportFlightPlanFilesButton.isEnabled = Services.hub.flightPlan.edition.currentFlightPlanValue != nil
        exportFlightPlanFilesButton.isHidden = Bundle.main.isInHouseBuild
        super.viewWillAppear(animated)
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension ParrotDebugViewController {
    @IBAction func doneAction(_ sender: UIButton) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyDebugLogsButton.done))
        dismiss(animated: true)
    }

    @IBAction private func toolBoxButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.showDevToolbox()
    }

    @IBAction private func showPGYDebug(_ sender: AnyObject) {
        coordinator?.showPhotogrammetryDebug()
    }

    @IBAction func startCustomMissionDebug(_ sender: Any) {
        coordinator?.showCustomMissionDebug()
    }

    @IBAction func enableStreamRecord(_ sender: UIButton) {
        ParrotDebug.createStreamDebugPath()
        updateStreamRecordDisplay()
        if ParrotDebug.streamDebugPathExists() {
            let alertController = UIAlertController(title: L10n.debugLogStreamRecord,
                                                    message: L10n.debugLogRestartApp,
                                                    preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: L10n.ok, style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

    @IBAction func switchLogOnOff(_ sender: UISwitch) {
        if sender.isOn {
            activateLog()
        } else {
            deactivateLog()
        }
        displayInformations()
        loadFileList()
    }

    @IBAction func switchLogDebugInfo(_ sender: UISwitch) {
        if sender.isOn {
            setLogDebug()
        } else {
            setLogInfo()
        }
    }

    @IBAction func debugCheckCOn(_ sender: Any) {
        Defaults.debugC = true
        if let drone = drone {
            drone.getPeripheral(Peripherals.wifiAccessPoint)?.isoCountryCode.value = Constants.usCountryCode
        }
        displayInformations()
    }

    @IBAction func debugCheckCOff(_ sender: Any) {
        Defaults.debugC = false
        displayInformations()
    }

    @IBAction private func sendDebugTagTouchedUpInside(_ sender: AnyObject) {
        guard let tagValue = self.sendDebugTagTextField.text,
              let devToolBox = self.drone?.getPeripheral(Peripherals.devToolbox) else {
            return
        }

        _ = self.sendDebugTagTextField.resignFirstResponder()
        self.sendDebugTagTextField.text = ""
        self.sendDebugTagButton.isEnabled = false

        // Send debug tag
        devToolBox.sendDebugTag(tag: tagValue)
    }

    @IBAction private func exportFlightPlanFiles(_ sender: AnyObject) {
        shareCurrentFlightPlanFiles()
    }
}

// MARK: - Private Funcs
private extension ParrotDebugViewController {
    func displayInformations() {
#if DEBUG
        // let debugBuild = true
        var messDebugBuild = L10n.debugLogBuildDebug
#else
        // let debugBuild = false
        var messDebugBuild = L10n.debugLogBuildRelease
#endif

        if Bundle.main.isInHouseBuild {
            messDebugBuild.append(" (InHouse)")
        }

        let messVersion = Bundle.main.infoDictionary?[Constants.bundleVersionKey] as? String ?? "?"

        let messDir: String
        if let logDirectory = currentLogDirectory {
            messDir = " - LOG: \(logDirectory)"
        } else {
            messDir = ""
        }

        let messAutoCountry = "\(Defaults.debugC == true ? "*" : "")" +
        "auto country(\(GroundSdkConfig.sharedInstance.autoSelectWifiCountry ? "Y" : "N"))" +
        "\(drone?.getPeripheral(Peripherals.wifiAccessPoint)?.isoCountryCode.value ?? "?")"

        let messageInfo = "\(messDebugBuild) v\(messVersion) \(messAutoCountry)\(messDir)"
        informationsLabel.text = messageInfo
    }

    func updateStreamRecordDisplay() {
        if ParrotDebug.streamDebugPathExists() {
            enableStreamRecord.isEnabled = false
            enableStreamRecord.setTitle(L10n.debugLogStreamRecordEnabled, for: .normal)
        }
    }

    func share(url: URL, sourceFrame: CGRect, coordinateSpace: UICoordinateSpace) {
        guard let logs = ParrotDebug.fileToShare(for: url) else {
            return
        }
        documentInteractionController = UIDocumentInteractionController()
        documentInteractionController.url = logs
        documentInteractionController.uti = Constants.defaultShareUti
        documentInteractionController.name = url.lastPathComponent
        let from = coordinateSpace.convert(sourceFrame, to: view)
        documentInteractionController.presentOptionsMenu(from: from, in: view, animated: true)
    }

    func rename(url: URL) {
        nameToRename = url.lastPathComponent
        // Declare Alert message
        let alertController = UIAlertController(title: L10n.debugLogRenameFile, message: "", preferredStyle: .alert)

        // OK button
        let okAction = UIAlertAction(title: L10n.ok.uppercased(), style: .default, handler: { [weak self] _ in
            if let renameValue = alertController.textFields?[0].text {
                ParrotDebug.renameLogFile(fromUrl: url, withLastComponent: renameValue)
                self?.loadFileList()
            }
        })
        renameOkAction = okAction
        okAction.isEnabled = false
        alertController.addAction(okAction)

        // Cancel button
        alertController.addAction(UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil))

        // Add Input TextField to dialog message
        alertController.addTextField { textField in
            textField.addTarget(self, action: #selector(self.renameDidChange(_:)), for: .editingChanged)
            textField.text = self.nameToRename
        }

        // Present dialog message to user
        self.present(alertController, animated: true, completion: nil)
    }

    @objc func renameDidChange(_ textField: UITextField) {
        if let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), text != nameToRename {
            renameOkAction?.isEnabled = true
        } else {
            renameOkAction?.isEnabled = false
        }
    }

    func loadFileList() {
        fileListUrls = ParrotDebug.listLogFiles().sorted { $0.lastPathComponent > $1.lastPathComponent }
        filesTableView.reloadData()
    }

    @objc func refreshFileList(_ sender: AnyObject) {
        loadFileList()
        refreshControl.endRefreshing()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ParrotDebugViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileListUrls.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let fileCell = tableView.dequeueReusableCell(withIdentifier: "FileCell", for: indexPath) as? ParrotLogFileCell {
            fileCell.fileName.text = fileListUrls[indexPath.row].lastPathComponent
            fileCell.fileName.isHighlighted = (fileCell.fileName.text == currentLogDirectory)
            return fileCell
        } else {
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: L10n.commonDelete) { [weak self] (_, _, _) in
            guard let self = self else { return }
            ParrotDebug.removeLogUrl(fileURL: self.fileListUrls[indexPath.row], srcVC: self) {
                self.fileListUrls.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }

        let shareAction = UIContextualAction(style: .normal, title: L10n.commonShare) { [weak self] (_, _, _) in
            guard let self = self else { return }
            let sourceFrame = tableView.rectForRow(at: indexPath)
            self.share(url: self.fileListUrls[indexPath.row],
                       sourceFrame: sourceFrame,
                       coordinateSpace: tableView)
        }
        shareAction.backgroundColor = UIColor.darkGray

        let renameAction = UIContextualAction(style: .normal, title: L10n.commonRename) { [weak self] (_, _, _) in
            guard let self = self else { return }
            self.rename(url: self.fileListUrls[indexPath.row])
        }
        renameAction.backgroundColor = UIColor.lightGray

        if fileListUrls[indexPath.row].lastPathComponent == currentLogDirectory {
            return UISwipeActionsConfiguration(actions: [shareAction])
        } else {
            return UISwipeActionsConfiguration(actions: [deleteAction, shareAction, renameAction])
        }
    }
}

// MARK: - UITextField delegate
extension ParrotDebugViewController: UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    public func textField(_ textField: UITextField,
                          shouldChangeCharactersIn range: NSRange,
                          replacementString string: String) -> Bool {
        if let tfCount = textField.text?.count {
            self.sendDebugTagButton.isEnabled = (tfCount + string.count) > 0
        }
        return true
    }
}

/// Class used for log file cell.
class ParrotLogFileCell: UITableViewCell {
    @IBOutlet var fileName: UILabel!
}

// MARK: - Flight Plan files DBG
extension ParrotDebugViewController {
    func shareCurrentFlightPlanFiles() {
        Task {
            // Ensure there is an opened FP.
            guard let flightPlan = Services.hub.flightPlan.edition.currentFlightPlanValue
            else { return }

            let planGenerator = Services.hub.flightPlan.planFileGenerator
            let flightPlanFilesManager = Services.hub.flightPlan.filesManager

            // Generate folder files files.
            if let result = try? await planGenerator.generatePlan(for: flightPlan) {
                let planDataFile = try? Data(contentsOf: flightPlanFilesManager.planFileUrl(for: flightPlan))
                let mavlinkFileData = result.flightPlan.dataSetting?.mavlinkDataFile

                if let folderUrl = try? flightPlanFilesManager.createFilesDirectory(for: result.flightPlan,
                                                                                    planFileData: planDataFile,
                                                                                    mavlinkFileData: mavlinkFileData) {
                    // Share the zipped folder.
                    await shareCurrentFlightPlanFilesFolder(folderUrl)
                    // Remove the created files.
                    try? FileManager.default.removeItem(at: folderUrl)
                    try? flightPlanFilesManager.removePlanFile(of: flightPlan)
                }
            }
        }
    }

    @MainActor
    func shareCurrentFlightPlanFilesFolder(_ url: URL) async {
        self.share(url: url,
                   sourceFrame: sendDebugTagButton.frame,
                   coordinateSpace: sendDebugTagButton)
    }
}

private extension ParrotDebugViewController {

    static func isLogActive() -> Bool {
        return ParrotDebug.currentLogDirectory?.lastPathComponent != nil
    }

    func activateLog() {
        ParrotDebug.startLog()
        switchLog.isOn = true
        logLevelSwitch.isEnabled = true
        logLevelSwitch.isEnabled = false  // TODO: remove this line once log level is dynamic -- it only exists to temporarily cancel out the previous line
        // Remember the log is on
        Defaults.activatedLog = true
        logLevel()
    }

    func deactivateLog() {
        switchLog.isOn = false
        logLevelSwitch.isEnabled = false // When there are no logs, the debug switch is irrelevant
        // Remember the log is off
        Defaults.activatedLog = false
        ParrotDebug.stopLog()
        logLevel()
    }

    func setLogDebug() {

        ULog.i(.tag, "ULOGLEVEL SET DEBUG (i)")
        ULog.d(.tag, "ULOGLEVEL SET DEBUG (d)")
        Defaults.debugLevel = "D"
        AppUtils.setLogLevel()
        ULog.d(.tag, "ULOGLEVEL SET DEBUG (d) DONE")
        logLevel()
    }

    func setLogInfo() {

        ULog.i(.tag, "ULOGLEVEL SET INFO (i)")
        ULog.d(.tag, "ULOGLEVEL SET INFO (d)")
        Defaults.debugLevel = "I"
        AppUtils.setLogLevel()
        ULog.d(.tag, "ULOGLEVEL SET INFO (d) DONE")
        logLevel()
    }

    func logLevel() {
        var log = "unknown"
        if let value = getenv("ULOG_LEVEL"), let logUtf8 = String(utf8String: value) {
            log = logUtf8
        }
        ULog.i(.tag, "ULOGLEVEL: \(log)")
    }
}
