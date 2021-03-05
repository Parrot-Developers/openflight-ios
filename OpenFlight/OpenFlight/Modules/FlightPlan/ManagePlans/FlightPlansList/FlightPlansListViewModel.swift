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
import CoreData

// MARK: - FlightPlansListDelegate
/// Protocol for FlightPlansListViewModel.
protocol FlightPlansListDelegate: class {
    /// Called when a flight plan is added or removed.
    func flightPlansUpdated()
}

// MARK: - FlightPlansListViewModel
/// View Model for a list of flight plans.
final class FlightPlansListViewModel {

    // MARK: - Private Properties
    private weak var delegate: FlightPlansListDelegate?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - delegate: delegate that notify when a flight plan is updated in device database.
    init(delegate: FlightPlansListDelegate) {
        guard let context = CoreDataManager.shared.currentContext else { return }
        self.delegate = delegate
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: context)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private Funcs
private extension FlightPlansListViewModel {

    /// Listen CoreData's FlightPlanModel add and remove to refresh view.
    @objc func managedObjectContextDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        // Check inserts.
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
           inserts.filter({ $0 is FlightPlanModel }).isEmpty == false {
            self.delegate?.flightPlansUpdated()
        } else if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
                  updates.filter({ $0 is FlightPlanModel }).isEmpty == false {
            self.delegate?.flightPlansUpdated()
        }// Check deletes.
        else if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>,
            deletes.filter({ $0 is FlightPlanModel }).isEmpty == false {
            self.delegate?.flightPlansUpdated()
        }
    }
}
