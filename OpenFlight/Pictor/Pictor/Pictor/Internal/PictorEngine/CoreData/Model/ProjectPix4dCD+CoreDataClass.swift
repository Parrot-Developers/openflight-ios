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
import CoreData

@objc(ProjectPix4dCD)
class ProjectPix4dCD: PictorEngineManagedObject {
    override internal var _uuid: String { uuid }

    override func update(_ model: PictorBaseModel) {
        if let model = model as? PictorBaseProjectPix4dModel {
            updateBaseModel(model)
        } else if let model = model as? PictorEngineBaseProjectPix4dModel {
            updateEngineModel(model)
        }
    }
}

private extension ProjectPix4dCD {

    func updateBaseModel(_ model: PictorBaseProjectPix4dModel) {
        uuid = model.uuid

        cloudId = model.cloudId
        title = model.title
        projectDate = model.projectDate
        processingCalled = model.processingCalled
    }

    func updateEngineModel(_ model: PictorEngineBaseProjectPix4dModel) {
        // - Base model
        updateBaseModel(model.projectPix4dModel)
        localCreationDate = model.localCreationDate
        localModificationDate = model.localModificationDate

        // - Synchro properties
        synchroStatus = model.synchroStatus.rawValue
        synchroError = model.synchroError.rawValue
        synchroLatestUpdatedDate = model.synchroLatestUpdatedDate
        synchroLatestStatusDate = model.synchroLatestStatusDate
        synchroIsDeleted = model.synchroIsDeleted
    }
}
