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

/// A class that encapsulates a value of generic type T and notify observer on value change.
public class Observable<T> {
    // MARK: - Public Properties
    /// Public accessible value from private one.
    public var value: T {
        return privateValue
    }

    /// Completion block executed when `value` property is updated.
    public var valueChanged: ((T) -> Void)?

    // MARK: - Private Properties
    /// Property used to store value of type T.
    /// Each update calls `valueChanged` completion block to notify observer.
    private var privateValue: T {
        didSet {
            let currentValue = privateValue
            DispatchQueue.main.async {
                self.valueChanged?(currentValue)
            }
        }
    }

    // MARK: - Init
    /// Inits.
    ///
    /// - Parameters:
    ///     - value: current observable value
    public init(_ value: T) {
        self.privateValue = value
    }
}

// MARK: - Public Funcs
public extension Observable where T: Equatable {
    /// Sets up a new value for T. Value is changed only if
    /// it is not nil and different from currently stored value.
    ///
    /// - Parameters:
    ///    - newValue: new value to set.
    ///    - force: force value to be updated and notified regardless of equality.
    func set(_ newValue: T?, force: Bool? = false) {
        guard let newValue = newValue,
               newValue != self.value || force == true else {
            return
        }

        self.privateValue = newValue
    }
}
