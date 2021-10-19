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

import GroundSdk

/// Settings content sub class dedicated to return to home settings.
final class SettingsRTHViewController: SettingsContentViewController {
    // MARK: - Private Properties
    private var maxGridHeight: CGFloat = 200.0

    // MARK: - Private Enums
    private enum Constants {
        static let firstCellIndex: Int = 0
        static let gridIndex: Int = 1
        static let minimumCellsCount: Int = 2
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        initViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Target iphone
        if !isRegularSizeClass {
            // Dedicated treatment with the right frame size.
                maxGridHeight = self.view.bounds.height
                    - self.settingsTableView.visibleCells[Constants.firstCellIndex].frame.size.height
                    - view.safeAreaInsets.bottom
        }

        settingsTableView.reloadData()
    }

    /// Reset to default settings.
    override func resetSettings() {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyAdvancedSettings.resetRTHSettings,
                             newValue: nil,
                             logType: LogEvent.LogType.button)

        viewModel?.resetSettings()
    }
}

// MARK: - Internal Funcs
extension SettingsRTHViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let cellType = cells[indexPath.row]

        switch cellType {
        case .rth:
            cell = configureRthCell(atIndexPath: indexPath)
        case .endHovering:
            cell = configureHoveringCell(atIndexPath: indexPath)
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
private extension SettingsRTHViewController {
    /// Inits the view.
    func initView() {
        resetCellLabel = L10n.settingsRthReset
    }

    /// Inits the view model.
    func initViewModel() {
        viewModel = SettingsRthViewModel()
        viewModel?.state.valueChanged = { [weak self] state in
            self?.updateDataSource(state)
        }

        if let state = viewModel?.state.value {
            updateDataSource(state)
        }
    }

    /// Configures Control Mode Cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: UITableViewCell.
    func configureRthCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = settingsTableView.dequeueReusableCell(for: indexPath) as SettingsRthCell
        cell.configureCell(maxGridHeight: maxGridHeight)

        return cell
    }

    /// Configures the end Hovering mode cell.
    ///
    /// - Parameters:
    ///     - indexPath: cell indexPath
    /// - Returns: UITableViewCell.
    func configureHoveringCell(atIndexPath indexPath: IndexPath) -> UITableViewCell {
        return settingsTableView.dequeueReusableCell(for: indexPath) as SettingsEndHoveringCell
    }
}
