//
//  Copyright (C) 2020 Parrot Drones SAS.
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

import GroundSdk

// MARK: - Internal Enums
/// Enum used to display camera timelapse sub-modes in bottom bar.
public enum TimeLapseMode: Int, BarItemSubMode {
    case halfSecond = 500
    case oneSecond = 1000
    case twoSeconds = 2000
    case fourSeconds = 4000
    case tenSeconds = 10000
    case thirtySeconds = 30000
    case sixtySeconds = 60000

    public static let allValues: [BarItemMode] = [TimeLapseMode.halfSecond,
                                           TimeLapseMode.oneSecond,
                                           TimeLapseMode.twoSeconds,
                                           TimeLapseMode.fourSeconds,
                                           TimeLapseMode.tenSeconds,
                                           TimeLapseMode.thirtySeconds,
                                           TimeLapseMode.sixtySeconds]

    public static var preset: TimeLapseMode { .twoSeconds }

    public var title: String { UnitHelper.formatSeconds(interval) }

    public var image: UIImage? { Asset.BottomBar.CameraModes.icCameraModeTimeLapse.image }

    public var key: String { String(rawValue) }

    public var value: Int? { rawValue }

    /// Timelapse interval in seconds.
    public var interval: Double { Double(rawValue) / 1000.0 }

    public var isAvailable: Bool {
        Camera2Params.currentSupportedTimelapseInterval()?.contains(interval) == true
    }

    public var shutterText: String? { nil }

    public var logKey: String { LogEvent.LogKeyHUDBottomBarButton.timeLapse.name }

    /// Gets supported values for a given photo resolution.
    ///
    /// - Parameter resolution: photo resolution
    /// - Returns: supported timelapse interval values
    public static func supportedValuesForResolution(for resolution: Camera2PhotoResolution) -> [TimeLapseMode] {
        guard let range = Camera2Params.supportedTimelapseInterval(for: resolution),
              let allValues = allValues as? [TimeLapseMode] else {
            return []
        }
        return allValues.filter { range.contains( $0.interval ) }
    }

    /// Constructor.
    ///
    /// - Parameter interval: timelapse interval expressed in seconds
    public init?(interval: Double) {
        self.init(rawValue: Int(interval * 1000))
    }
}
