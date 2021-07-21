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

/// Manages available Flight Plan types.
public protocol FlightPlanTypeStore: AnyObject {
    /// Register a flight plan type
    func register(_ type: FlightPlanType)
    /// Find a flight plan type given a key
    func typeForKey(_ key: String?) -> FlightPlanType?
}

public final class FlightPlanTypeStoreImpl: FlightPlanTypeStore {

    // MARK: - Private Properties
    private var types = [String: FlightPlanType]()

    public init() {
        ClassicFlightPlanType.allCases.forEach({
            self.register($0)
        })
    }

    // MARK: - Public Funcs
    /// Registers a Flight Plan type.
    ///
    /// - Parameters:
    ///    - type: Flight Plan type
    public func register(_ type: FlightPlanType) {
        types[type.key] = type
    }

    /// Returns Flight Plan type associated to given key, if it exists.
    ///
    /// - Parameters:
    ///    - key: Flight Plan type key
    /// - Returns: associated registered Flight Plan type, if any
    public func typeForKey(_ key: String?) -> FlightPlanType? {
        guard let key = key else { return nil }
        return types[key]
    }
}
