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

import UIKit

// MARK: - Internal Enums
/// Enum representing an alert level.

enum AlertLevel {
    /// No alert.
    case ready
    /// No state.
    case none
    /// Warning/Minor alert.
    case warning
    /// Critical alert.
    case critical

    /// Default color associated with alert level.
    var color: UIColor {
        switch self {
        case .warning:
            return UIColor(named: .orangePeel)
        case .critical:
            return UIColor(named: .redTorch)
        default:
            return .clear
        }
    }

    /// Color for radar components.
    var radarColor: UIColor {
        switch self {
        case .warning:
            return UIColor(named: .orangePeel)
        case .critical:
            return UIColor(named: .redTorch)
        default:
            return UIColor(named: .highlightColor)
        }
    }

    /// Returns true if alert level is warning or critical.
    var isWarningOrCritical: Bool {
        switch self {
        case .critical, .warning:
            return true
        default:
            return false
        }
    }
}
