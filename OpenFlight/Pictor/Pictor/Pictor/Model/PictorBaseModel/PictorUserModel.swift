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

// MARK: - Protocol
public protocol PictorBaseUserModel: PictorBaseModel {
    // - Info
    var apcId: String { get }
    var academyId: String { get set }
    var email: String { get set }
    var firstName: String { get set }
    var lastName: String { get set }
    var isPrivateMode: Bool? { get set }

    // - Account
    var apcToken: String? { get set }
    var confirmed: Bool{ get set }

    // - Optional
    // Info
    var pilotNumber: Int? { get set }
    var gender: String? { get set }
    var phone: String? { get set }
    var country: String? { get set }
    var language: String? { get set }
    var company: String? { get set }
    var vatNumber: Int? { get set }
    var registrationNumber: Int? { get set }
    var subIndustry: String? { get set }
    var industry: String? { get set }
    var store: String? { get set }
    var isCaligoffEnabled: Bool { get set }

    // - Pix4d
    var nbFreemiumProjects: Int { get set }

    // - Local
    var isAgreementChanged: Bool { get set }
    var avatarImageData: Data? { get set }
}

// MARK: - Model
public struct PictorUserModel: PictorBaseUserModel, Equatable {
    // MARK: Properties
    public private(set) var uuid: String

    // - Info
    public var apcId: String { uuid }
    public var academyId: String
    public var email: String
    public var firstName: String
    public var lastName: String
    public var isPrivateMode: Bool?

    // - Account
    public var apcToken: String?
    public var confirmed: Bool

    // - Optional
    // Info
    public var pilotNumber: Int?
    public var gender: String?
    public var phone: String?
    public var country: String?
    public var language: String?
    public var company: String?
    public var vatNumber: Int?
    public var registrationNumber: Int?
    public var subIndustry: String?
    public var industry: String?
    public var store: String?
    public var isCaligoffEnabled: Bool

    // - Pix4d
    public var nbFreemiumProjects: Int

    // - Local
    public var isAgreementChanged: Bool
    public var avatarImageData: Data?

    // MARK: Init
    init(uuid: String,
         academyId: String,
         email: String,
         firstName: String,
         lastName: String,
         isPrivateMode: Bool?,
         apcToken: String?,
         confirmed: Bool,
         pilotNumber: Int?,
         gender: String?,
         phone: String?,
         country: String?,
         language: String?,
         company: String?,
         vatNumber: Int?,
         registrationNumber: Int?,
         subIndustry: String?,
         industry: String?,
         store: String?,
         isCaligoffEnabled: Bool,
         nbFreemiumProjects: Int,
         isAgreementChanged: Bool,
         avatarImageData: Data?) {
        self.uuid = uuid

        // - Info
        self.academyId = academyId
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.isPrivateMode = isPrivateMode

        // - Account
        self.apcToken = apcToken
        self.confirmed = confirmed

        // - Optional
        // Info
        self.pilotNumber = pilotNumber
        self.gender = gender
        self.phone = phone
        self.country = country
        self.language = language
        self.company = company
        self.vatNumber = vatNumber
        self.registrationNumber = registrationNumber
        self.subIndustry = subIndustry
        self.industry = industry
        self.store = store
        self.isCaligoffEnabled = isCaligoffEnabled

        // - Pix4d
        self.nbFreemiumProjects = nbFreemiumProjects

        // - Local
        self.isAgreementChanged = isAgreementChanged
        self.avatarImageData = avatarImageData
    }

    internal init(record: UserCD) {
        self.init(uuid: record.uuid,
                  academyId: record.academyId,
                  email: record.email,
                  firstName: record.firstName,
                  lastName: record.lastName,
                  isPrivateMode: record.isPrivateMode?.boolValue,
                  apcToken: record.apcToken,
                  confirmed: record.confirmed,
                  pilotNumber: record.pilotNumber?.intValue,
                  gender: record.gender,
                  phone: record.phone,
                  country: record.country,
                  language: record.language,
                  company: record.company,
                  vatNumber: record.vatNumber?.intValue,
                  registrationNumber: record.registrationNumber?.intValue,
                  subIndustry: record.subIndustry,
                  industry: record.industry,
                  store: record.store,
                  isCaligoffEnabled: record.isCaligoffEnabled,
                  nbFreemiumProjects: Int(record.nbFreemiumProjects),
                  isAgreementChanged: record.isAgreementChanged,
                  avatarImageData: record.avatarImageData)
    }
}
