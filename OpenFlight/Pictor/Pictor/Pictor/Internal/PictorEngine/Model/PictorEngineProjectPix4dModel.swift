//    Copyright (C) 2022 Parrot Drones SAS
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

protocol PictorEngineBaseProjectPix4dModel: PictorEngineSynchroBaseModel {
    var projectPix4dModel: PictorProjectPix4dModel { get }
}

struct PictorEngineProjectPix4dModel: PictorEngineBaseProjectPix4dModel {
    // MARK: Properties
    var uuid: String { baseModel.uuid }

    // MARK: - Engine base model
    var baseModel: PictorBaseModel { projectPix4dModel }
    var projectPix4dModel: PictorProjectPix4dModel
    var localCreationDate: Date?
    var localModificationDate: Date?

    // MARK: - Engine synchro base model
    var synchroStatus: PictorEngineSynchroStatus
    var synchroError: PictorEngineSynchroError
    var synchroLatestStatusDate: Date?
    var synchroLatestUpdatedDate: Date?
    var synchroIsDeleted: Bool

    init(projectPix4dModel: PictorProjectPix4dModel,
         localCreationDate: Date? = nil,
         localModificationDate: Date? = nil,
         synchroStatus: PictorEngineSynchroStatus = .notSync,
         synchroError: PictorEngineSynchroError = .noError,
         synchroLatestStatusDate: Date? = nil,
         synchroLatestUpdatedDate: Date? = nil,
         synchroIsDeleted: Bool = false) {
        self.projectPix4dModel = projectPix4dModel
        self.localCreationDate = localCreationDate
        self.localModificationDate = localModificationDate
        self.synchroStatus = synchroStatus
        self.synchroError = synchroError
        self.synchroLatestStatusDate = synchroLatestStatusDate
        self.synchroLatestUpdatedDate = synchroLatestUpdatedDate
        self.synchroIsDeleted = synchroIsDeleted
    }

    init(model: PictorProjectPix4dModel, record: ProjectPix4dCD) {
        self.init(projectPix4dModel: model,
                  localCreationDate: record.localCreationDate,
                  localModificationDate: record.localModificationDate,
                  synchroStatus: PictorEngineSynchroStatus(rawValue: record.synchroStatus) ?? .notSync,
                  synchroError: PictorEngineSynchroError(rawValue: record.synchroError) ?? .noError,
                  synchroLatestStatusDate: record.synchroLatestStatusDate,
                  synchroLatestUpdatedDate: record.synchroLatestUpdatedDate,
                  synchroIsDeleted: record.synchroIsDeleted)
    }
}

extension PictorEngineProjectPix4dModel: Equatable {
    static func == (lhs: PictorEngineProjectPix4dModel, rhs: PictorEngineProjectPix4dModel) -> Bool {
        return lhs.projectPix4dModel == rhs.projectPix4dModel
            && lhs.localCreationDate == rhs.localCreationDate
            && lhs.localModificationDate == rhs.localModificationDate
            && lhs.synchroStatus == rhs.synchroStatus
            && lhs.synchroError == rhs.synchroError
            && lhs.synchroLatestStatusDate == rhs.synchroLatestStatusDate
            && lhs.synchroLatestUpdatedDate == rhs.synchroLatestUpdatedDate
            && lhs.synchroIsDeleted == rhs.synchroIsDeleted
    }
}
