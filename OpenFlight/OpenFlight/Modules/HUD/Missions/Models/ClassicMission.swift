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

// MARK: - Internal Structs
/// Classic mission provider struct.
struct ClassicMission: MissionProvider {
    // MARK: - Internal Properties
    var mission: Mission

    var signature: AirSdkMissionSignature = DefaultMissionSignature()

    // MARK: - Static content
    static var manualModeConf = MissionModeConfigurator(key: MissionsConstants.classicMissionManualKey,
                                                        name: L10n.missionModeManual,
                                                        icon: Asset.MissionModes.icClassicMissionMode.image,
                                                        logName: LogEvent.LogKeyHUDMissionProviderSelectorButton.manual,
                                                        preferredSplitMode: .split,
                                                        isMapRequired: false,
                                                        isRightPanelRequired: false,
                                                        isTrackingMode: false,
                                                        isAeLockEnabled: true,
                                                        isInstallationRequired: true,
                                                        isCameraShutterButtonEnabled: true,
                                                        isTargetOnStream: false)
    static var manualMode = MissionMode(configurator: manualModeConf,
                                        customMapProvider: {
                                            StoryboardScene.PilotingMap.initialScene.instantiate()
                                        },
                                        bottomBarLeftStack: { () -> [UIView] in
                                            return [BehaviourModeView()]
                                        },
                                        bottomBarRightStack: ImagingStackElement.classicStack)
}
