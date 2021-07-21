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

import Foundation
import Combine
import CoreData

protocol ManagePlansViewModelDelegate: AnyObject {
    /// End manage plans
    ///
    /// - Parameters:
    ///     - shouldStartEdition: String value of corresponding name
    ///     - shouldCenter: should center position on map
    func endManagePlans(shouldStartEdition: Bool, shouldCenter: Bool)
}

/// Protocol allow to communicate from UIViewController to ViewModel
protocol ManagePlansViewModelInput {

    /// Child flight plan list ViewModel
    var flightPlanListviewModel: FlightPlansListViewModelParentInput! { get }

    /// Publisher that give new value of title if needed, to reset current textField
    var resetTitlePublisher: AnyPublisher<String, Never> { get }

    /// Publisher that give new value of flight plan state
    var statePublisher: AnyPublisher<ManagePlansState, Never> { get }

    /// User asks for a flight plan renaming
    ///
    /// - Parameters:
    ///     - name: String value of corresponding name
    func renameSelectedFlightPlan(_ name: String)

    /// User asks for opening the currently selected flight plan
    func openSelectedFlightPlan()

    /// User asks for closing the "manage plans" view
    func closeManagePlans()

    /// User asks for duplicating the currently selected flight plan
    func duplicateSelectedFlightPlan()

    /// User asks for deleting the currently selected flight plan
    func deleteSelectedFlightPlan()

    /// User asks for creating a new flight plan
    func newFlightPlan()

    /// Set compact mode
    func setToCompactMode()
}

/// State flight plan type
public enum ManagePlansState {
    case noFlightPlan
    case flightPlan(name: FlightPlanViewModel)
}

class ManagePlansViewModel {

    /// Own delegate
    private weak var delegate: ManagePlansViewModelDelegate?

    /// Mainly providing the type of the FPs
    private let flightPlanProvider: FlightPlanProvider

    /// Persistence access for flight plans
    private let persistence: FlightPlanDataProtocol

    /// Child flight plan list ViewModel
    private(set) var flightPlanListviewModel: FlightPlansListViewModelParentInput!

    /// Main manager, providing the "current flight plan" management. Do not confuse with the selected flight plan of this VM
    private let manager: FlightPlanManager

    /// Update text to current title, when modification dismissed
    private var resetTitle = PassthroughSubject<String, Never>()

    /// State of flight plan
    @Published private var state: ManagePlansState = .noFlightPlan

    /// The flight plan that controls will target
    private var selectedFlightPlan: FlightPlanViewModel? {
        didSet {
            if let flightPlan = selectedFlightPlan {
                state = .flightPlan(name: flightPlan)
                flightPlanListviewModel.updateUUID(with: flightPlan.state.value.uuid)
            } else {
                state = .noFlightPlan
                flightPlanListviewModel.updateUUID(with: nil)
            }
        }
    }

    /// Just retaining a listener to unregister later
    private var listener: FlightPlanListener!

    /// Constructor
    /// - Parameters:
    ///   - delegate: delegate handling the end of this subprocess
    ///   - flightPlanProvider: contextual provider determining the type of flight plans displayed
    ///   - persistence: flight plans persistence access
    ///   - manager: flight plan manager
    init(delegate: ManagePlansViewModelDelegate,
         flightPlanProvider: FlightPlanProvider,
         persistence: FlightPlanDataProtocol,
         manager: FlightPlanManager) {
        // Set properties
        self.delegate = delegate
        self.flightPlanProvider = flightPlanProvider
        self.persistence = persistence
        self.manager = manager
    }

    func setupFlightPlanListviewModel(viewModel: FlightPlansListViewModelParentInput) {
        self.flightPlanListviewModel = viewModel
        self.flightPlanListviewModel.setupDelegate(with: self)
    }

    func start() {
        // The listener is called immediately
        self.listener = manager.register(didChange: { [weak self] in
            // Each time there's a new flight plan considered as current or its attributes change,
            // we update the selected flight plan to this new value.
            // This may happen after duplication, deletion, creation, opening...
            // The inverse is not true : the user may select a flight plan in the UI and not open it
            self?.selectedFlightPlan = $0
        })

        // Init data
        let flightPlans = reloadAllFlightPlans()

        // TODO: observing changes should be done on some manager / store instead of watching the CoreData context directly
        // Once it's done, delete the exposure of currentContext in the protocol
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(managedObjectContextDidChange),
                                               name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: persistence.currentContext)
        // TODO: this shouldn't be done here OMG. Also, maybe explain why isn't the type of the fps considered ? Anyway the manager should not expect
        // to get the list of plans from the outside to do this.
        manager.syncFlightPlansWithFiles(persistedFlightPlans: flightPlans) { [weak self] _ in
            self?.reloadAllFlightPlans()
        }
    }

    deinit {
        manager.unregister(listener)
    }

}

// MARK: - Private funcs
private extension ManagePlansViewModel {

    @discardableResult
    func reloadAllFlightPlans() -> [FlightPlanViewModel] {
        let allFlightPlans = persistence.loadAllFlightPlanViewModels(predicate: flightPlanProvider.filterPredicate)
        flightPlanListviewModel.setupFlightPlans(with: allFlightPlans)
        return allFlightPlans
    }
}

// MARK: - ManagePlansViewControllerDelegate
extension ManagePlansViewModel: ManagePlansViewModelInput {

    var statePublisher: AnyPublisher<ManagePlansState, Never> {
        $state.eraseToAnyPublisher()
    }

    var resetTitlePublisher: AnyPublisher<String, Never> {
        resetTitle.eraseToAnyPublisher()
    }

    func renameSelectedFlightPlan(_ name: String) {
        guard let oldTitle = selectedFlightPlan?.state.value.title else { return }
        let correctTitle = manager.setupTitle(name, oldTitle: oldTitle)
        guard oldTitle != correctTitle else {
            resetTitle.send(oldTitle)
            return
        }
        selectedFlightPlan?.rename(correctTitle)
    }

    func openSelectedFlightPlan() {
        guard let flightPlan = self.selectedFlightPlan else { return }
        flightPlan.setAsLastUsed()
        manager.currentFlightPlanViewModel = flightPlan
        delegate?.endManagePlans(shouldStartEdition: false, shouldCenter: flightPlan.isEmpty)
    }

    func closeManagePlans() {
        delegate?.endManagePlans(shouldStartEdition: false, shouldCenter: false)
    }

    func duplicateSelectedFlightPlan() {
        guard let flightPlan = self.selectedFlightPlan else { return }
        manager.duplicate(flightPlan: flightPlan)
    }

    func deleteSelectedFlightPlan() {
        guard let flightplan = self.selectedFlightPlan,
                      !flightplan.runFlightPlanViewModel.state.value.runState.isActive else {
            // TODO display anything ?
            // Else should just prevent this action properly
                return
            }
        self.selectedFlightPlan = nil
        manager.delete(flightPlan: flightplan)
        // The manager may have set a new flight plan as current, causing this VM to already update its selected flight plan
        // Else, we can try this fallback
        if self.selectedFlightPlan == nil {
            self.selectedFlightPlan = manager.currentFlightPlanViewModel
        }
    }

    func newFlightPlan() {
        manager.new(flightPlanProvider: flightPlanProvider)
        delegate?.endManagePlans(shouldStartEdition: true, shouldCenter: true)
    }

    func setToCompactMode() {
        flightPlanListviewModel.setupDisplayMode(with: .compact)
    }
}

// MARK: - FlightPlansListViewControllerDelegate
extension ManagePlansViewModel: FlightPlansListViewModelDelegate {
    func didDoubleTapOn(flightplan: FlightPlanViewModel) {
        openSelectedFlightPlan()
    }

    func didSelect(flightPlan: FlightPlanViewModel) {
        self.selectedFlightPlan = flightPlan
    }
}

// MARK: - Notifications
private extension ManagePlansViewModel {

    /// Listen CoreData's FlightPlanModel add and remove to refresh view.
    @objc func managedObjectContextDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        // Check inserts.
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
           inserts.contains(where: { $0 is FlightPlanModel }) {
            reloadAllFlightPlans()
        } else if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>,
            updates.contains(where: { $0 is FlightPlanModel }) {
            reloadAllFlightPlans()
        }// Check deletes.
        else if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>,
            deletes.contains(where: { $0 is FlightPlanModel }) {
            reloadAllFlightPlans()
        }
    }
}
