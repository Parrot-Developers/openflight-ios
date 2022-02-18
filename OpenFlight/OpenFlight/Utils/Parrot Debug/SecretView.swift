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

import UIKit

@IBDesignable
/// UIControl allowing the entry of a secret code. When the code is detected, the control generates the `.valueChanged`
/// event.
///
/// Use: insert a UIVIew in the storyboard and hide it using the transparent color. Change the class to `SecretView`
/// Define inspectable properties: `secretCode` and `delayMax` (maximum time between two keys).
class SecretView: UIControl {

    /// The secret code. The scretView has 4 areas :
    ///
    /// +-------+
    ///
    /// | 1 | 2 |
    ///
    /// +-------+
    ///
    /// | 3 | 4 |
    ///
    /// +-------+
    ///
    /// The user must tap hidden areas to enter a number.
    @IBInspectable var secretCode: String = ""

    /// Maximum allowed delay between two entries of a code digit. Failure to respect this deadline cancels any
    /// previous entries
    @IBInspectable var delayMax: Double = 1.5

    /// Last event timeStamp
    private var lastTouchTimeStamp: TimeInterval = 0
    /// Code being entered
    private var currentCode = ""

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        // SecretView is a "PassTrough" UIVIew - checks also any "secret hit"
        if hitView == self {
            if let event = event, event.type == .touches && lastTouchTimeStamp != event.timestamp {
                let delay = event.timestamp - lastTouchTimeStamp
                lastTouchTimeStamp = event.timestamp
                checkSecretHit(point, delaySincePrevious: delay)
            }
            return nil
        } else {
            return hitView
        }
    }

    /// Check the secret code value entry
    ///
    /// - Parameters:
    ///   - point: point where the touch is
    ///   - delaySincePrevious: elapsed time since the last "secret hit"
    private func checkSecretHit(_ point: CGPoint, delaySincePrevious: TimeInterval) {
        guard !secretCode.isEmpty else {
            return
        }
        if delaySincePrevious > delayMax {
            currentCode = ""
        }
        // find the number in 4 areas
        let row = point.y > bounds.size.height * 0.5 ? 1 : 0
        let col = point.x > bounds.size.width * 0.5 ? 1 : 0
        let valueCode = col + (row * 2) + 1
        if currentCode.count == secretCode.count {
            currentCode.removeFirst()
        }
        currentCode.append(String(valueCode))
        if currentCode == secretCode {
            // secret code is detected
            sendActions(for: .valueChanged)
        }
    }
}
