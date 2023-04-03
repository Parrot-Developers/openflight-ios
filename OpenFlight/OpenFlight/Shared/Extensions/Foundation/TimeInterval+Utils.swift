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

import Foundation

/// Utility extension for `TimeInterval`.
public extension TimeInterval {
    /// Returns a string containing current time interval with MM:SS format.
    var formattedString: String {
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60)
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Returns a string containing current time interval with HH:MM:SS format.
    var longFormattedString: String {
        let interval = Int(self)
        let hours = interval / 3600
        let seconds = (interval % 3600) % 60
        let minutes = (interval % 3600) / 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Returns a string containing current time interval with HH:MM:SS or MM:SS format.
    var adaptiveFormattedString: String {
        let interval = Int(self)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = (interval % 3600) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Returns a string containing current time interval with HMS format.
    var formattedHmsString: String? {
        let durationFormatter = DateComponentsFormatter()
        durationFormatter.allowedUnits = [.hour, .minute]
        let showOnlyMinutes = self < TimeInterval.oneHour
        let showOnlyHours = self >= 10 * TimeInterval.oneHour
        durationFormatter.unitsStyle = showOnlyHours || showOnlyMinutes ? .brief : .abbreviated
        durationFormatter.maximumUnitCount = showOnlyHours ? 1 : 2
        return durationFormatter.string(from: self)
    }
}

public extension TimeInterval {
    var hourMinuteSecondMillisecond: String {
        String(format: "%d:%02d:%02d.%03d", hour, minute, second, millisecond)
    }
    var hourMinuteSecond: String {
        String(format: "%d:%02d:%02d", hour, minute, second)
    }
    var minuteSecondMillisecond: String {
        String(format: "%d:%02d.%03d", minute, second, millisecond)
    }
    var minuteSecond: String {
        String(format: "%d:%02d", minute, second)
    }
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}

/// Convenience static helpers for second/minute/hour usage.
public extension TimeInterval {

    static var oneSecond: TimeInterval { 1 }
    static var oneMinute: TimeInterval { 60 * oneSecond }
    static var oneHour: TimeInterval { 60 * oneMinute }
}

extension Int {
    var msToSeconds: Double { Double(self) / 1000 }
}
