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

/// Utility extension for `Double`.

extension Double {
    /// Returns square value.
    var square: Double {
        return self * self
    }

    /// Returns current value as a positive degree value.
    /// Should be used to convert [-180, 180] angles to [0, 360].
    var asPositiveDegrees: Double {
        return self > 0 ? self : self + 360.0
    }

    /// Rounds the double to decimal places value.
    ///
    /// - Parameters:
    ///    - places: number of decimal figures
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    /// Returns the double value as string percent formated.
    ///
    /// - Parameters:
    ///    - maximumFractionDigits: maximum fraction digits
    /// - Returns: percent string formated
    func asPercent(maximumFractionDigits: Int = 2, multiplier: NSNumber = 1.0) -> String {
        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.multiplier = multiplier
        percentFormatter.maximumFractionDigits = maximumFractionDigits
        let value = percentFormatter.string(from: NSNumber(value: self)) ?? "\(self)%"
        // Replace "no break space" character (if exists) because it breaks
        // display in a string formatter with %s.
        return value.replacingOccurrences(of: Style.noBreakSpace, with: " ")
    }

    /// Gets whether this value is close to another one
    ///
    /// - Parameters:
    ///   - other: the other value
    ///   - delta: the maximal acceptance delta
    /// - Returns: `true` if this value is equal to the other one with the given acceptation delta
    func isCloseTo(_ other: Double, withDelta delta: Double) -> Bool {
        return abs(self - other) <= delta
    }
}
