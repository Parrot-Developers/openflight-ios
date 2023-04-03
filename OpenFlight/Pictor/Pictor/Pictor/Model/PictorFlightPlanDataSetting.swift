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

public class PictorFlightPlanDataSetting: Decodable {
    // MARK: - Waypoints
    public class WayPoint: Decodable { }

    // MARK: - Static
    public static func new(fromData: Data?) -> PictorFlightPlanDataSetting? {
        guard let json = fromData,
              let result = try? JSONDecoder().decode(Self.self, from: json) else {
            return nil
        }
        return result
    }

    // MARK: - Properties
    public var pgyProjectId: Int64?
    public var hasReachedFirstWayPoint: Bool?
    public var executionRank: Int?
    public var wayPoints: [WayPoint]?

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.wayPoints = try? container.decode([WayPoint].self, forKey: .wayPoints)
        self.pgyProjectId = try? container.decode(Int64.self, forKey: .pgyProjectId)
        self.hasReachedFirstWayPoint = try? container.decode(Bool.self, forKey: .hasReachedFirstWayPoint)
        self.executionRank = try? container.decode(Int.self, forKey: .executionRank)
    }
}

// MARK: - Private
private extension PictorFlightPlanDataSetting {
    private enum CodingKeys: String, CodingKey {
        case wayPoints

        // PGY
        case pgyProjectId

        // FP State
        case hasReachedFirstWayPoint
        case executionRank
    }
}
