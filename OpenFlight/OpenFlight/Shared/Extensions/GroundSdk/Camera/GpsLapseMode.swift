//    Copyright (C) 2020 Parrot Drones SAS
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
/// Enum used to display camera GPS Lapse sub-modes in bottom bar.
public enum GpsLapseMode: Int, BarItemSubMode {
    case halfMeter = 500
    case oneMeter = 1000
    case twoMeters = 2000
    case fiveMeters = 5000
    case tenMeters = 10000
    case twentyMeters = 20000
    case fiftyMeters = 50000
    case oneHundredMeters = 100000
    case twoHundredMeters = 200000

    public static let allValues: [BarItemMode] = [
        GpsLapseMode.halfMeter,
        GpsLapseMode.oneMeter,
        GpsLapseMode.twoMeters,
        GpsLapseMode.fiveMeters,
        GpsLapseMode.tenMeters,
        GpsLapseMode.twentyMeters,
        GpsLapseMode.fiftyMeters,
        GpsLapseMode.oneHundredMeters,
        GpsLapseMode.twoHundredMeters]

    public static var preset: GpsLapseMode {
        return .tenMeters
    }

    public var title: String {
        return UnitHelper.stringDistanceWithDouble(interval, useFractionDigit: true)
    }

    public var image: UIImage? {
        return Asset.BottomBar.CameraModes.icCameraModeGpsLapse.image
    }

    public var key: String {
        return String(rawValue)
    }

    public var value: Int? {
        return rawValue
    }

    /// Gpslapse interval in meters.
    public var interval: Double { Double(rawValue) / 1000.0 }

    public var isAvailable: Bool {
        Camera2Params.currentSupportedGpslapseInterval()?.contains(interval) == true
    }

    public var shutterText: String? {
        return nil
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.gpsLapse.name
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - interval: gpslapse interval in meters
    public init?(interval: Double) {
        self.init(rawValue: Int(interval * 1000))
    }
}
