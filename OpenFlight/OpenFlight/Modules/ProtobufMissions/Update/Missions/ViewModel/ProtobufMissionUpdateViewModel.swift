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
import SwiftProtobuf

// MARK: - ProtobufMissionUpdateState
/// The states for `ProtobufMissionUpdateViewModel`.
public final class ProtobufMissionUpdateState: ViewModelState, Copying, EquatableState {
    // MARK: - Internal Properties
    fileprivate(set) var missionToUpdateStatus: ProtobufMissionToUpdateStatus = .notInUpdateList

    // MARK: - Init
    public required init() {}

    /// Init the mission states.
    ///
    /// - Parameters:
    ///   - missionToUpdateStatus: The mission to update status
    init(missionToUpdateStatus: ProtobufMissionToUpdateStatus) {
        self.missionToUpdateStatus = missionToUpdateStatus
    }

    // MARK: - EquatableState
    public func isEqual(to other: ProtobufMissionUpdateState) -> Bool {
        return self.missionToUpdateStatus == other.missionToUpdateStatus
    }

    // MARK: - Copying
    public func copy() -> ProtobufMissionUpdateState {
        return ProtobufMissionUpdateState(missionToUpdateStatus: self.missionToUpdateStatus)
    }
}

// MARK: - ProtobufMissionUpdateViewModel
/// The view model that handles a protobuf mission update.
public final class ProtobufMissionUpdateViewModel: BaseViewModel<ProtobufMissionUpdateState> {
    // MARK: - Private Properties
    private var protobufMissionsUpdaterManager = ProtobufMissionsUpdaterManager.shared
    private var listener: ProtobufMissionUpdaterListener?

    // MARK: - Private Enums
    private enum Constants {
        static let maxProgress: Int = 100
        static let minProgress: Int = 0
    }

    // MARK: - Public Properties
    let missionToUpdateData: ProtobufMissionToUpdateData

    // MARK: - Init
    /// Inits
    ///
    /// - Parameters:
    ///     - missionToUpdateData: mission to update data
    init(missionToUpdateData: ProtobufMissionToUpdateData) {
        self.missionToUpdateData = missionToUpdateData
        super.init()

        listenMissionUpdate()
    }

    // MARK: - Deinit
    deinit {
        protobufMissionsUpdaterManager.unregister(listener)
    }

    // MARK: - Public Funcs
    /// Cancels all potentials updates.
    ///
    /// - Returns: True if the operation was successful.
    func cancelProtobufMissionUpdate() -> Bool {
        switch state.value.missionToUpdateStatus {
        case .notInUpdateList,
             .waitingForUpdate,
             .failed,
             .updateDone:
            return true
        case let .onGoingUpdate(missionUpdateTast):
            guard let task = missionUpdateTast.task else {
                // Cancelation impossible.
                return false
            }
            task.cancel()
            return true
        }
    }

    /// Returns the current progress for the mission.
    ///
    /// - Returns: The current progress for the mission
    func currentProgress() -> Int {
        switch state.value.missionToUpdateStatus {
        case .waitingForUpdate,
             .notInUpdateList:
            return Constants.minProgress
        case let .onGoingUpdate(missionUpdateTast):
            return missionUpdateTast.progress
        case .failed,
             .updateDone:
            return Constants.maxProgress
        }
    }
}

// MARK: - Equatable
extension ProtobufMissionUpdateViewModel: Equatable {
    public static func == (lhs: ProtobufMissionUpdateViewModel,
                           rhs: ProtobufMissionUpdateViewModel) -> Bool {
        return lhs.missionToUpdateData == rhs.missionToUpdateData
    }
}

// MARK: - Private Funcs
private extension ProtobufMissionUpdateViewModel {
    /// Listen to the  mission update.
    func listenMissionUpdate() {
        listener = protobufMissionsUpdaterManager
            .register(for: missionToUpdateData,
                      missionToUpdateCallback: { [weak self] (status) in
                        self?.update(missionToUpdateStatus: status)
                      })
    }
}

/// Utils for updating states of `ProtobufMissionUpdateState`.
private extension ProtobufMissionUpdateViewModel {
    /// Updates the state.
    ///
    /// - Parameters:
    ///     - missionToUpdateStatus: The mission update status
    func update(missionToUpdateStatus: ProtobufMissionToUpdateStatus) {
        let copy = self.state.value.copy()
        copy.missionToUpdateStatus = missionToUpdateStatus
        self.state.set(copy)
    }
}
