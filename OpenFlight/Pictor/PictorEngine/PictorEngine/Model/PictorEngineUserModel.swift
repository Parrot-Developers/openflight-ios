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

public protocol PictorEngineBaseUserModel: PictorEngineBaseModel {
    var name: String { get set }
    var email: String { get set }
}

public struct PictorEngineUserModel: PictorEngineBaseUserModel {
    private var _uuid: String
    public var uuid: String {
        return _uuid
    }

    public var email: String

    public var name: String

    public init(uuid: String, email: String, name: String) {
        self._uuid = uuid
        self.email = email
        self.name = name
    }
}

public struct PictorEngineUserSynchroModel: PictorEngineBaseUserModel, PictorEngineBaseSynchroModel {
    private var _uuid: String
    public var uuid: String {
        return _uuid
    }

    public var synchro: String

    public var email: String

    public var name: String

    public init(uuid: String, email: String, name: String, synchro: String) {
        self._uuid = uuid
        self.email = email
        self.name = name
        self.synchro = synchro
    }

    public static func request(uuids: [String]?, names: [String]?, emails: [String]?, synchros: [String]?) -> NSFetchRequest<UserCD> {
        let fetchRequest = UserCD.fetchRequest()
        var subPredicates: [NSPredicate] = []

        if let uuids = uuids {
            let uuidPredicate = NSPredicate(format: "uuid IN %@", uuids)
            subPredicates.append(uuidPredicate)
        }
        if let names = names {
            let namePredicate = NSPredicate(format: "name IN %@", names)
            subPredicates.append(namePredicate)
        }
        if let emails = emails {
            let emailPredicate = NSPredicate(format: "email IN %@", emails)
            subPredicates.append(emailPredicate)
        }
        if let synchros = synchros {
            let synchroPredicate = NSPredicate(format: "synchro IN %@", synchros)
            subPredicates.append(synchroPredicate)
        }

        let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicates)
        fetchRequest.predicate = compoundPredicates
        return fetchRequest
    }
}
