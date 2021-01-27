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

/// Manages a list of `HUDAlertType`.

final class AlertList {
    // MARK: - Private Properties
    private var allAlerts: [HUDAlertType] = []

    // MARK: - Internal Properties
    /// Returns current highest priority alert if any.
    var mainAlert: HUDAlertType? {
        guard let firstAlert = allAlerts.first else {
            return nil
        }
        return allAlerts.reduce(firstAlert) { (result, alert) -> HUDAlertType in
            return alert.hasHigherPriority(than: result) ? alert : result
        }
    }

    // MARK: - Internal Funcs
    /// Adds given alerts to list.
    ///
    /// - Parameters:
    ///    - alerts: list of alerts to add
    func addAlerts(_ alerts: [HUDAlertType]) {
        allAlerts.append(contentsOf: alerts)
    }

    /// Removes alerts of given categories from list.
    ///
    /// - Parameters:
    ///    - categories: list of categories
    func cleanAlerts(withCategories categories: [AlertCategoryType]) {
        allAlerts.removeAll(where: { categories.contains($0.category) })
    }
}
