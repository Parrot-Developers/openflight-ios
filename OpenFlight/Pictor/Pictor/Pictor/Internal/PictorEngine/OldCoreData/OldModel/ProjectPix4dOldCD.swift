//    Copyright (C) 2023 Parrot Drones SAS
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

struct OldProjectPix4dModel: OldModel {
    var _uuid: String { "\(pgyProjectId)" }
    var _userUuid: String { apcId }

    var apcId: String!
    var pgyProjectId: Int64
    var name: String!
    var processingCalled: Bool
    var projectDate: Date!
    var latestSynchroStatusDate: Date?
    var synchroStatus: Int16
    var isLocalDeleted: Bool
    var latestLocalModificationDate: Date?
    var synchroError: Int16
}

@objc(PgyProject)
class PgyProject: OldManagedObject {
    override var _uuid: String { "\(pgyProjectId)" }
    override var _userUuid: String { apcId }

    func toModel() -> OldProjectPix4dModel {
        OldProjectPix4dModel(apcId: apcId,
                             pgyProjectId: pgyProjectId,
                             name: name,
                             processingCalled: processingCalled,
                             projectDate: projectDate,
                             latestSynchroStatusDate: latestSynchroStatusDate,
                             synchroStatus: synchroStatus,
                             isLocalDeleted: isLocalDeleted,
                             latestLocalModificationDate: latestLocalModificationDate,
                             synchroError: synchroError)
    }
}

extension PgyProject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PgyProject> {
        return NSFetchRequest<PgyProject>(entityName: Self.entityName)
    }

    // MARK: - Properties

    @NSManaged public var apcId: String!
    @NSManaged public var pgyProjectId: Int64
    @NSManaged public var name: String!
    @NSManaged public var processingCalled: Bool
    @NSManaged public var projectDate: Date!
    @NSManaged public var latestSynchroStatusDate: Date?
    @NSManaged public var synchroStatus: Int16
    @NSManaged public var isLocalDeleted: Bool
    @NSManaged public var latestLocalModificationDate: Date?
    @NSManaged public var synchroError: Int16

    // MARK: - Relationship

    @NSManaged public var ofUserParrot: UserParrot?
}
