//    Copyright (C) 2022 Parrot Drones SAS
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

import Combine

/// The bottom bar service.
public protocol HudBottomBarService: AnyObject {
    /// The bottom bar current mode getter.
    var mode: BottomBarMode { get }
    /// The bottom bar current mode publisher.
    var modePublisher: AnyPublisher<BottomBarMode, Never> { get }
    /// Sets bottom bar to a specific mode.
    func set(mode: BottomBarMode)
    /// Pops bottom bar (i.e. closes last level).
    /// Returns `true` if a level has been closed, `false` otherwise.
    func pop() -> Bool
}

// MARK: - The service implementation.
open class HudBottomBarServiceImpl {
    /// Bottom bar current mode value.
    private let modeSubject = CurrentValueSubject<BottomBarMode, Never>(.preset)
}

extension HudBottomBarServiceImpl: HudBottomBarService {
    /// The bottom bar current mode getter.
    public var mode: BottomBarMode { modeSubject.value }
    /// The bottom bar current mode publisher.
    public var modePublisher: AnyPublisher<BottomBarMode, Never> { modeSubject.eraseToAnyPublisher() }

    /// Sets bottom bar to a specific mode.
    ///
    /// - Parameter mode: the mode to set the bottom bar to
    public func set(mode: BottomBarMode) {
        modeSubject.value = mode
    }

    /// Pops bottom bar (i.e. closes last level).
    ///
    /// - Returns: `true` if a level has been closed, `false` otherwise
    public func pop() -> Bool {
        switch mode {
        case .closed:
            // Bottom bar is already fully closed => return `false`.
            return false
        case .levelOneOpened:
            // Level one is currently opened => fully close bottom bar and return `true`.
            set(mode: .closed)
            return true
        case .levelTwoOpened:
            // Level two is currently opened => close it (set mode to level one) and return `true`.
            set(mode: .levelOneOpened)
            return true
        }
    }
}
