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

import Foundation

class EditionSettingsViewModel {

    enum ViewState {
        case updateUndo(FlightPlanSettingCategory?)
        case selectedGraphic(EditableAGSGraphic?)
        case reload
    }

    @Published private(set) var viewState: ViewState?

    /// Provider used to get the settings of the flight plan provider.
    var settingsProvider: FlightPlanSettingsProvider?
    /// The current flight plan which contains the settings.
    var savedFlightPlan: FlightPlanModel? {
        didSet {
            guard let strongFlightPlan = savedFlightPlan else { return }

            self.fpSettings = settingsProvider?.settings(for: strongFlightPlan)
        }
    }

    enum Setting {
        case separator
        case setting(FlightPlanSetting)
    }

    // MARK: - Private Properties
    private var fpSettings: [FlightPlanSetting]?
    private var editionService: FlightPlanEditionService?
    private(set) var settingsCategoryFilter: FlightPlanSettingCategory?
    var dataSource: [Setting] {
        let settings = self.fpSettings ?? self.settingsProvider?.settings ?? []
        let actualSettings: [Setting]
        if let filter = settingsCategoryFilter {
            actualSettings = settings
                .filter { $0.category == filter && $0.type != .fixed }
            // Filter not editable settings for imported mavlinks.
                .filter(for: savedFlightPlan)
                .map { Setting.setting($0) }
        } else {
            actualSettings = settings
                .filter { $0.type != .fixed }
                .map { Setting.setting($0) }
        }
        let separators = settings.map { _ in Setting.separator }
        // interleave the two equal sized arrays (settings + separators)
        // result: put a separator after each setting
        let finalSettings = zip(actualSettings, separators)
            .map { [$0, $1] } // setting + separator
            .map { settingNseparator -> [Setting] in
                let setting = settingNseparator[0]
                if case let Setting.setting(flightPlanSetting) = setting,
                   flightPlanSetting.key == "buildingHeight" {
                    return [setting] // remove separator for buildingHeight
                }
                return settingNseparator
            }
            .flatMap { $0 }
            .dropLast() // remove final separator
        return Array(finalSettings)
    }

    // Init
    init(editionService: FlightPlanEditionService?) {
        self.editionService = editionService
    }

    /// Refreshes view data.
    ///
    /// - Parameters:
    ///     - categoryFilter: allows to filter setting category
    func refreshContent(categoryFilter: FlightPlanSettingCategory?) {
        viewState = .updateUndo(categoryFilter)
        settingsCategoryFilter = categoryFilter
        viewState = .reload
    }

    // MARK: - Internal Funcs
    /// Update collection view data.
    ///
    /// - Parameters:
    ///     - settingsProvider: current settings provider
    ///     - savedFlightPlan: current flight plan
    ///     - selectedGraphic: selected graphic
    func updateDataSource(with settingsProvider: FlightPlanSettingsProvider?,
                          savedFlightPlan: FlightPlanModel?,
                          selectedGraphic: EditableAGSGraphic?) {
        self.settingsProvider = settingsProvider
        self.savedFlightPlan = savedFlightPlan
        // Delete button is hidden if selected graphic can't be deleted or if no graphic is selected.
        viewState = .selectedGraphic(selectedGraphic)

        switch settingsProvider {
        case is WayPointSettingsProvider,
             is PoiPointSettingsProvider,
             is WayPointSegmentSettingsProvider:
            self.fpSettings = settingsProvider?.settings
        case nil:
            self.fpSettings = []
            settingsCategoryFilter = .custom(L10n.flightPlanSegmentSettingsTitle)
        default:
            break
        }

        viewState = .reload
        refreshContent(categoryFilter: settingsCategoryFilter)

        // Update the editionService's modifiedFlightPlan to handle changes.
        if let savedFlightPlan = savedFlightPlan {
            editionService?.updateModifiedFlightPlan(with: savedFlightPlan)
        }
    }

    /// Refreshes view data.
    func refreshContent() {
        refreshContent(categoryFilter: self.settingsCategoryFilter)
    }
}
