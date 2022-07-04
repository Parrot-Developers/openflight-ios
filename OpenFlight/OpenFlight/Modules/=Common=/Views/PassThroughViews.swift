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

/// A `UIWindow` passing touch events to parent.
public class PassThroughWindow: UIWindow {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
}

/// A `UIView` passing touch events to parent.
public class PassThroughView: UIView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
}

/// A `UIStackView` passing touch events to parent.
public class PassThroughBasicStackView: UIStackView {
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? nil : hitView
    }
}

/// A `UIViewController` passing its background view touch events to parent.
public class PassThroughViewController: UIViewController {
    public override func loadView() {
        super.loadView()
        view = PassThroughView(frame: UIScreen.main.bounds)
    }
}

/// A `UIStackView` passing touch events detected outside of `touchViews` IBOutlets array to parent.
class PassThroughStackView: UIStackView {
    // MARK: - Outlets
    /// Views to enable touch in stack view.
    /// Touches are send through otherwise.
    @IBOutlet var touchViews: [UIView]!

    // MARK: - Override Funcs
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return touchViews.contains(where: {
            !$0.isHidden
                && $0.isUserInteractionEnabled
                && $0.point(inside: self.convert(point, to: $0), with: event)
        })
    }
}
