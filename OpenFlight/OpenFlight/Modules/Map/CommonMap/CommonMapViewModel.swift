//    Copyright (C) 2021 Parrot Drones SAS
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
import Combine
import ArcGIS
import GroundSdk

/// ViewModel for `CommonMapViewController`
public class CommonMapViewModel {
    // MARK: Private Properties
    private let locationsTracker: LocationsTracker = Services.hub.locationsTracker
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// Network service
    private let networkService: NetworkService = Services.hub.systemServices.networkService

    // MARK: Public Properties
    public var networkReachablePublisher: AnyPublisher<Bool, Never> { networkService.networkReachable }
    public var centerStatePublisher: AnyPublisher<MapCenterState, Never> { centerState.eraseToAnyPublisher() }
    public var centerState = CurrentValueSubject<MapCenterState, Never>(.none)

    public var isMiniMapPublisher: AnyPublisher<Bool, Never> { isMiniMap.eraseToAnyPublisher() }
    public var isMiniMap = CurrentValueSubject<Bool, Never>(false)
    public var largeMapRatio: Double?

    /// Terrain elevation source.
    public var keyboardIsHidden: Bool = true
    public var lastValidPoints: (screen: CGPoint?, map: AGSPoint?)

    // MARK: Init

    /// Init
    /// - Parameters:
    ///  - networkService: the network service
    init() {

        // Add keyboard observer to block or not touch on the map.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    @objc private func keyboardWillAppear() {
        keyboardIsHidden = false
    }

    @objc private func keyboardWillDisappear() {
        keyboardIsHidden = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
}
