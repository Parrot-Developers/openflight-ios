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

// MARK: - Public Structs
/// Object which handles medias view in the history table view cell.
public struct HistoryMediasView {
    /// View to display.
    var view: UIView?
    /// Custom action on this view.
    var actionType: HistoryMediasActionType?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - view: view to display
    ///     - actionType; action on the view
    public init(view: UIView?, actionType: HistoryMediasActionType?) {
        self.view = view
        self.actionType = actionType
    }
}

// MARK: - Protocols
/// Stores history sync methods.
public protocol HistorySyncProvider {
    /// Provides a dictionnary with id and corresponding view.
    ///
    /// - Parameters:
    ///     - type: current history type
    ///     - flightPlanViewModel: current flight plan view model
    func historySyncViews(type: HistoryTableType, flightPlanViewModel: FlightPlanViewModel?) -> [String: HistoryMediasView]
}

// MARK: - FlightPlanHistorySyncManager
/// Provides sync status about each flight plan execution in history.
public class FlightPlanHistorySyncManager {
    // MARK: - Public Properties
    /// History provider.
    public var syncProvider: HistorySyncProvider?
    /// Instance of this manager.
    public static let shared: FlightPlanHistorySyncManager = FlightPlanHistorySyncManager()

    // MARK: - Init
    private init() { }
}
