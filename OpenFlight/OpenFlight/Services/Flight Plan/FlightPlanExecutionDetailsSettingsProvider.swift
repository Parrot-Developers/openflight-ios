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

// swiftlint:disable type_name force_unwrapping

import Foundation

public protocol FlightPlanExecutionDetailsSettingsProvider {
    /// Add another provider in the execution chain.
    ///
    /// - Parameter provider: another settings provider
    func add(provider: FlightPlanExecutionDetailsSettingsProvider)

    /// Returns the key/value pairs that need to be displaed for a Flight Plan execution.
    ///
    /// - Parameter execution: a Flight Plan execution.
    func settings(forExecution execution: FlightPlanModel) -> [(key: String, value: String)]
}

class FlightPlanExecutionDetailsSettingsProviderImpl: FlightPlanExecutionDetailsSettingsProvider {
    private var providers: [FlightPlanExecutionDetailsSettingsProvider] = []

    func add(provider: FlightPlanExecutionDetailsSettingsProvider) {
        providers.append(provider)
    }

    func settings(forExecution execution: FlightPlanModel) -> [(key: String, value: String)] {
        let otherSettings = providers.flatMap { $0.settings(forExecution: execution) }
        if !otherSettings.isEmpty {
            return otherSettings
        }
        guard let dataSetting = execution.dataSetting else {
            return []
        }

        let captureMode = dataSetting.captureModeEnum
        let captureModeSettings = [
            FlightPlanCaptureMode.gpsLapse: [ClassicFlightPlanSettingType.photoResolution,
                                             ClassicFlightPlanSettingType.gpsLapseDistance],
            FlightPlanCaptureMode.timeLapse: [ClassicFlightPlanSettingType.photoResolution,
                                              ClassicFlightPlanSettingType.timeLapseCycle],
            FlightPlanCaptureMode.video: [ClassicFlightPlanSettingType.resolution,
                                          ClassicFlightPlanSettingType.framerate]
        ]
        let desiredSettings =
            captureModeSettings[captureMode]!
            + [ClassicFlightPlanSettingType.exposure,
               ClassicFlightPlanSettingType.whiteBalance]
        let values = desiredSettings.map { setting -> String in
            if let value = setting.currentValue(forFlightPlan: execution),
               let descriptions = setting.valueDescriptions(forFlightPlan: execution),
               descriptions.startIndex <= value, value < descriptions.endIndex {
                return descriptions[value]
            } else if setting == ClassicFlightPlanSettingType.timeLapseCycle,
                      let value = setting.currentValue(forFlightPlan: execution),
                      let mode = TimeLapseMode(rawValue: value) {
                return mode.title
            } else if setting == ClassicFlightPlanSettingType.gpsLapseDistance,
                      let value = setting.currentValue(forFlightPlan: execution),
                      let mode = GpsLapseMode(rawValue: value) {
                return mode.title
            } else {
                return Style.dash
            }
        }
        return [
            (L10n.dashboardMyFlightsProjectExecutionSettingsMode, captureMode.title)
        ] + zip(desiredSettings, values).map { ($0.0.title, $0.1) }
    }
}
