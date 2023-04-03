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
public protocol PictorBaseSessionModel: PictorBaseModel {
    var pix4dEmail: String { get set }
    var pix4dAccessToken: String? { get set }
    var pix4dRefreshToken: String? { get set }
    var permanentRemainingPix4dProjects: Int { get set }
    var temporaryRemainingPix4dProjects: Int { get set }
    var pix4dPremiumTokenExpirationDate: Date? { get set }
    var pix4dPremiumAccountScopes: String? { get set }
    var pix4dPremiumAccountTokenType: String? { get set }
    var pix4dPremiumProjectsCountLastSyncDate: Date? { get set }
    var pix4dFreemiumProjectsCountLastSyncDate: Date? { get set }
}

// MARK: - Model
public struct PictorSessionModel: PictorBaseSessionModel, Equatable {
    // MARK: Properties
    private(set) public var uuid: String

    // - Pix4d
    public var pix4dEmail: String
    public var pix4dAccessToken: String?
    public var pix4dRefreshToken: String?
    public var permanentRemainingPix4dProjects: Int
    public var temporaryRemainingPix4dProjects: Int
    public var pix4dPremiumTokenExpirationDate: Date?
    public var pix4dPremiumAccountScopes: String?
    public var pix4dPremiumAccountTokenType: String?
    public var pix4dPremiumProjectsCountLastSyncDate: Date?
    public var pix4dFreemiumProjectsCountLastSyncDate: Date?

    init(uuid: String,
         pix4dEmail: String,
         pix4dAccessToken: String?,
         pix4dRefreshToken: String?,
         pix4dPremiumTokenExpirationDate: Date?,
         pix4dPremiumAccountScopes: String?,
         pix4dPremiumAccountTokenType: String?,
         pix4dPremiumProjectsCountLastSyncDate: Date?,
         pix4dFreemiumProjectsCountLastSyncDate: Date?,
         permanentRemainingPix4dProjects: Int,
         temporaryRemainingPix4dProjects: Int) {
        self.uuid = uuid
        self.pix4dEmail = pix4dEmail
        self.pix4dAccessToken = pix4dAccessToken
        self.pix4dRefreshToken = pix4dRefreshToken
        self.pix4dPremiumTokenExpirationDate = pix4dPremiumTokenExpirationDate
        self.pix4dPremiumAccountScopes = pix4dPremiumAccountScopes
        self.pix4dPremiumAccountTokenType = pix4dPremiumAccountTokenType
        self.pix4dPremiumProjectsCountLastSyncDate = pix4dPremiumProjectsCountLastSyncDate
        self.pix4dFreemiumProjectsCountLastSyncDate = pix4dFreemiumProjectsCountLastSyncDate
        self.permanentRemainingPix4dProjects = permanentRemainingPix4dProjects
        self.temporaryRemainingPix4dProjects = temporaryRemainingPix4dProjects
    }

    internal init(record: SessionCD) {
        self.init(uuid: record.uuid,
                  pix4dEmail: record.pix4dEmail,
                  pix4dAccessToken: record.pix4dAccessToken,
                  pix4dRefreshToken: record.pix4dRefreshToken,
                  pix4dPremiumTokenExpirationDate: record.pix4dPremiumTokenExpirationDate,
                  pix4dPremiumAccountScopes: record.pix4dPremiumAccountScopes,
                  pix4dPremiumAccountTokenType: record.pix4dPremiumAccountTokenType,
                  pix4dPremiumProjectsCountLastSyncDate: record.pix4dPremiumProjectsCountLastSyncDate,
                  pix4dFreemiumProjectsCountLastSyncDate: record.pix4dFreemiumProjectsCountLastSyncDate,
                  permanentRemainingPix4dProjects: Int(record.permanentRemainingPix4dProjects),
                  temporaryRemainingPix4dProjects: Int(record.temporaryRemainingPix4dProjects))
    }
}
