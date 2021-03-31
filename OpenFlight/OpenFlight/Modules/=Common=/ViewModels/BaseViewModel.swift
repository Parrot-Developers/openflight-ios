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

// MARK: - Protocols
/// Base model state protocol.
public protocol ViewModelState {
    init()
}

/// Protocol for equatable states.
public protocol EquatableState: Equatable {
    /// Returns true if given object is equal to self.
    ///
    /// - Parameters:
    ///    - other: object to compare
    /// - Returns: true if object is equal to self, false otherwise
    func isEqual(to other: Self) -> Bool
}

extension EquatableState {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.isEqual(to: rhs)
    }
}

/// Base ViewModel with a private state.
open class BaseViewModel<T: ViewModelState> {
    // MARK: - Internal Enums
    /// State object to represent model. Setter must be private.
    /// `state` object is `Observable` and so can be observed.
    public var state: Observable<T>

    // MARK: - Init
    /// Init
    ///
    /// - Parameter stateDidUpdate: completion block to notify state changes.
    @available(*, deprecated, message: "Use init without parameters")
    public init(stateDidUpdate: ((T) -> Void)?) {
        state = Observable(T())
        state.valueChanged = stateDidUpdate
    }

    /// Init.
    public init() {
        state = Observable(T())
    }
}
