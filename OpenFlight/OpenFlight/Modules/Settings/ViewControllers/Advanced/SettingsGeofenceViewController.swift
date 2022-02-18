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

/// Settings content sub class dedicated to Geofence settings.

final class SettingsGeofenceViewController: SettingsContentViewController {
    // MARK: - Private Properties
    private var geofenceViewModel: GeofenceViewModel?
    private var maxGridHeight: CGFloat {
        return view.bounds.height
        - Layout.buttonIntrinsicHeight(isRegularSizeClass)
        - view.directionalLayoutMargins.bottom
        - view.directionalLayoutMargins.top
    }

    // MARK: - Private Enums
    private enum Constants {
        static let gridIndex: Int = 1
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupViewModel()
    }

    override func settingsSegmentedCellDidChange(selectedSegmentIndex: Int, atIndexPath indexPath: IndexPath) {
        let settingEntry = filteredSettings[indexPath.row]
        settingEntry.save(at: selectedSegmentIndex)
    }

    /// Reset to default settings.
    override func resetSettings() {
        LogEvent.log(.simpleButton(LogEvent.LogKeyAdvancedSettings.resetGeofenceSettings))

        geofenceViewModel?.resetSettings()
    }

    override func settingEntries() -> [SettingEntry]? {
        return geofenceViewModel?.settingEntries
    }
}

// MARK: - Internal Funcs
internal extension SettingsGeofenceViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellType = cells[indexPath.row]

        switch cellType {
        case .grid:
            cell = configureGridCell(atIndexPath: indexPath)
        default:
            cell = super.tableView(tableView, cellForRowAt: indexPath)
        }
        cell.selectionStyle = .none

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row != Constants.gridIndex ? UITableView.automaticDimension : maxGridHeight
    }
}

// MARK: - Private Funcs
private extension SettingsGeofenceViewController {

    /// Initializes view.
    func initView() {
        view.directionalLayoutMargins = Layout.mainContainerInnerMargins(isRegularSizeClass,
                                                                         screenBorders: [.top, .bottom])
        resetCellLabel = L10n.settingsGeofenceReset
    }

    /// Sets up view model.
    func setupViewModel() {
        // Setup view model.
        geofenceViewModel = GeofenceViewModel()
        geofenceViewModel?.state.valueChanged = { [weak self] state in
            self?.updateDataSource(state)
        }
        // Inital data source update.
        updateDataSource(GeofenceState())
    }

    /// Configure Grid Mode Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: UITableViewCell
    func configureGridCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsGridTableViewCell
        cell.configureCell(maxGridHeight: maxGridHeight)

        return cell
    }
}
