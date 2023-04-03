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

struct OldDroneModel: OldModel {
    var _uuid: String { droneSerial }
    var _userUuid: String { apcId }

    var apcId: String
    var droneCommonName: String?
    var droneSerial: String
    var modelId: String?
    var pairedFor4G: Bool
    var synchroDate: Date?
    var synchroStatus: Int16
}

@objc(DronesData)
class DronesData: OldManagedObject {
    override var _uuid: String { droneSerial }
    override var _userUuid: String { apcId }

    func toModel() -> OldDroneModel {
        OldDroneModel(apcId: apcId,
                      droneCommonName: droneCommonName,
                      droneSerial: droneSerial,
                      modelId: modelId,
                      pairedFor4G: pairedFor4G,
                      synchroDate: synchroDate,
                      synchroStatus: synchroStatus)
    }
}

extension DronesData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DronesData> {
        return NSFetchRequest<DronesData>(entityName: Self.entityName)
    }

    // MARK: - Properties

    @NSManaged public var apcId: String!
    @NSManaged public var droneCommonName: String?
    @NSManaged public var droneSerial: String!
    @NSManaged public var modelId: String?
    @NSManaged public var pairedFor4G: Bool
    @NSManaged public var synchroDate: Date?
    @NSManaged public var synchroStatus: Int16

    // MARK: - Relationship

    @NSManaged public var ofUserParrot: UserParrot?

}

