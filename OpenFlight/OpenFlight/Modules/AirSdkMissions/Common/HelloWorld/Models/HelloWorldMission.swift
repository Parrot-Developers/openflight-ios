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

import Foundation
import GroundSdk

/// Hello World mission provider struct.
struct HelloWorldMission: MissionProvider {
    // MARK: - Internal Properties
    var mission: Mission {
        return Mission(key: String(describing: HelloWorldMission.self),
                       name: L10n.missionHello,
                       icon: Asset.MissionModes.MissionSubModes.icHelloWorld.image,
                       logName: "TODO", // TODO: Add log name
                       mode: HelloWorldMissionMode.standard.missionMode)
    }

    var signature: AirSdkMissionSignature = HelloWorldMissionSignature()
}

/// Enum for Hello World mission modes.
enum HelloWorldMissionMode: String, CaseIterable {
    case standard = "hello_world_standard_mode"

    var missionMode: MissionMode {
        let configurator = MissionModeConfigurator(key: self.rawValue,
                                                   name: self.title,
                                                   icon: self.icon,
                                                   logName: "TODO", // TODO: Add log name
                                                   preferredSplitMode: self.preferredSplitMode,
                                                   isMapRequired: false,
                                                   isRightPanelRequired: self.isRightPanelRequired,
                                                   isTrackingMode: false,
                                                   isAeLockEnabled: false,
                                                   isInstallationRequired: true,
                                                   isCameraShutterButtonEnabled: true,
                                                   isTargetOnStream: false)

        return MissionMode(configurator: configurator,
                           missionActivationModel: HelloWorldMissionViewModel(),
                           bottomBarLeftStack: {
                            self.bottomBarViews
                           },
                           bottomBarRightStack: [])
    }

    // MARK: - Private Properties
    private var title: String {
        switch self {
        case .standard:
            return  L10n.missionHello
        }
    }

    private var icon: UIImage {
        switch self {
        case .standard:
            return Asset.MissionModes.MissionSubModes.icHelloWorld.image
        }
    }

    private var preferredSplitMode: SplitScreenMode {
        switch self {
        case .standard:
            return .split
        }
    }

    private var isRightPanelRequired: Bool {
        return false
    }

    private var bottomBarViews: [UIView] {
        var views: [UIView] = []

        switch self {
        case .standard:
            views = [BehaviourModeView(),
                     HelloWorldBottomView()]
        }

        return views
    }
}
