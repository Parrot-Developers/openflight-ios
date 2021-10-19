//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Combine

/// UITextField Publishers
extension UITextField {
    /// Editing Changed Publisher
    var editingChangedPublisher: AnyPublisher<String, Never> {
        publisher(for: .editingChanged)
            .map { self.text ?? "" }
            .eraseToAnyPublisher()
    }

    /// Editing Did Begin Publisher
    var editingDidBeginPublisher: UIControlEventPublisher { publisher(for: .editingDidBegin) }

    /// Editing Did End Publisher
    var editingDidEndPublisher: UIControlEventPublisher { publisher(for: .editingDidEnd) }

    /// Return Key Pressed Publisher
    var returnPressedPublisher: TextFieldReturnPressedPublisher { TextFieldReturnPressedPublisher(textField: self) }
}

/// TextField Return Pressed Publisher
struct TextFieldReturnPressedPublisher: Publisher {
    typealias Output = Void
    typealias Failure = Never

    private let textField: UITextField

    init(textField: UITextField) {
        self.textField = textField
    }

    func receive<S: Subscriber>(subscriber: S) where
        S.Input == Output,
        S.Failure == Failure {
        let subscription = TextFieldReturnPressedSubscription(subscriber: subscriber, textField: textField)
        subscriber.receive(subscription: subscription)
    }
}

/// Tao Gesture Subscription
private class TextFieldReturnPressedSubscription<S: Subscriber>: NSObject, Subscription, UITextFieldDelegate where
    S.Input == Void {

    private var subscriber: S?
    private let textField: UITextField

    init(subscriber: S, textField: UITextField) {
        self.subscriber = subscriber
        self.textField = textField
        super.init()
        self.textField.delegate = self
    }

    func request(_ demand: Subscribers.Demand) {}

    func cancel() { subscriber = nil }

    @objc private func handler() {
        _ = subscriber?.receive()
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handler()
        return true
    }
}
