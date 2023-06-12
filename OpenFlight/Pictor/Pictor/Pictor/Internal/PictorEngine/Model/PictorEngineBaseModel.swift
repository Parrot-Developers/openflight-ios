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

protocol PictorEngineBaseModel: PictorBaseModel {
    /// The base model.
    var baseModel: PictorBaseModel { get }
    /// The creation date in the database.
    var localCreationDate: Date? { get set }
    /// The modification date in the database.
    var localModificationDate: Date? { get set }
}

protocol PictorEngineSynchroBaseModel: PictorEngineBaseModel {
    var cloudId: Int64 { get set }
    var synchroStatus: PictorEngineSynchroStatus { get set }
    var synchroError: PictorEngineSynchroError { get set }
    var synchroLatestUpdatedDate: Date? { get set }
    var synchroLatestStatusDate: Date? { get set }
    var synchroIsDeleted: Bool { get set }
}

enum PictorEngineSynchroStatus: Int16 {
    case notSync = 0
    case toUploadFile = 1
    case fileUpload = 2
    case synced = 3

    public init?(status: Int16?) {
        guard let rawValue = status else { return nil }
        self.init(rawValue: rawValue)
    }
}

enum PictorEngineSynchroError: Int16 {
    case noError = 0
    case noInternetConnection = 1
    case serverError = 500

    public init?(error: Int16?) {
        guard let rawValue = error else { return nil }
        self.init(rawValue: rawValue)
    }
}
