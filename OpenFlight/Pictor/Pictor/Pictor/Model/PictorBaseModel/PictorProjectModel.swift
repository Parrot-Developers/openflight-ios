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
public protocol PictorBaseProjectModel: PictorBaseModel {
    var cloudId: Int64 { get set }
    var title: String { get set }
    var type: PictorProjectModel.ProjectType { get set }
    var latestExecutionIndex: Int? { get set }
    var lastUpdated: Date? { get set }
    var lastOpened: Date? { get set }

    var editableFlightPlan: PictorFlightPlanModel? { get set }
    var latestExecutedFlightPlan: PictorFlightPlanModel? { get set }
}

// MARK: - Model
public struct PictorProjectModel: PictorBaseProjectModel, Equatable {
    public enum ProjectType: String {
        case classic
        case pgy

        public init?(rawString: String?) {
            guard let rawValue = rawString else { return nil }
            self.init(rawValue: rawValue)
        }
    }

    // MARK: Public Properties
    public private(set) var uuid: String

    public var cloudId: Int64
    public var title: String
    public var type: ProjectType
    public var latestExecutionIndex: Int?
    public var lastUpdated: Date?
    public var lastOpened: Date?

    // - Model Specifics
    public var editableFlightPlan: PictorFlightPlanModel?
    public var latestExecutedFlightPlan: PictorFlightPlanModel?

    // MARK: Init
    init(uuid: String,
         cloudId: Int64,
         title: String,
         type: ProjectType,
         latestExecutionIndex: Int?,
         lastUpdated: Date?,
         lastOpened: Date?) {
        self.uuid = uuid
        self.cloudId = cloudId
        self.title = title
        self.type = type
        self.latestExecutionIndex = latestExecutionIndex
        self.lastUpdated = lastUpdated
        self.lastOpened = lastOpened
    }

    internal init(record: ProjectCD,
                  editableFlightPlan: PictorFlightPlanModel?,
                  latestExecutedFlightPlan: PictorFlightPlanModel?) {
        self.init(uuid: record.uuid,
                  cloudId: record.cloudId,
                  title: record.title,
                  type: PictorProjectModel.ProjectType(rawValue: record.type ?? "") ?? .classic,
                  latestExecutionIndex: record.latestExecutionIndex?.intValue,
                  lastUpdated: record.lastUpdated,
                  lastOpened: record.lastOpened)
        self.editableFlightPlan = editableFlightPlan
        self.latestExecutedFlightPlan = latestExecutedFlightPlan
    }

    // MARK: Public
    public init(title: String,
                type: ProjectType,
                latestExecutionIndex: Int?,
                lastUpdated: Date?,
                lastOpened: Date?) {
        self.init(uuid: UUID().uuidString,
                  cloudId: 0,
                  title: title,
                  type: type,
                  latestExecutionIndex: latestExecutionIndex,
                  lastUpdated: lastUpdated,
                  lastOpened: lastOpened)
    }

    public func duplicate(title: String) -> PictorProjectModel {
        PictorProjectModel(uuid: UUID().uuidString,
                           cloudId: 0,
                           title: title,
                           type: type,
                           latestExecutionIndex: nil,
                           lastUpdated: Date(),
                           lastOpened: nil)
    }
}
