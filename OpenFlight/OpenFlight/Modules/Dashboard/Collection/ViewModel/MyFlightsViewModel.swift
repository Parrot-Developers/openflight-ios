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

import CoreData

// MARK: - MyFlightsState
/// State for for `MyFlightsViewModel`.
public final class MyFlightsState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Number of flights.
    public fileprivate(set) var numberOfFlights: Int = 0
    /// Last flight date.
    fileprivate(set) var date: String?
    /// Last flight duration.
    fileprivate(set) var duration: String?
    /// Last flight distance.
    fileprivate(set) var distance: String?
    /// Total flights duration.
    public fileprivate(set) var totalFlightsDuration: String?
    /// Total flights distance.
    public fileprivate(set) var totalFlightsDistance: String?
    /// Last flight.
    fileprivate(set) var lastFlight: FlightDataState?
    /// Boolean describing whether last flight has issues.
    var hasIssues: Bool {
        // TODO: compute this property from information on flights when available.
        return false
    }

    // MARK: - Init
    required public init() {}

    /// Init.
    ///
    /// - Parameters:
    ///    - numberOfFlights: number of flights
    ///    - date: last flight date
    ///    - duration: last flight duration
    ///    - distance: last flight distance
    ///    - totalFlightsDuration: sum of all flights duration
    ///    - totalFlightsDistance: sum of all flights distance
    ///    - lastFlight: last flight
    init(numberOfFlights: Int,
         date: String?,
         duration: String?,
         distance: String?,
         totalFlightsDuration: String?,
         totalFlightsDistance: String?,
         lastFlight: FlightDataState?) {
        self.numberOfFlights = numberOfFlights
        self.date = date
        self.duration = duration
        self.distance = distance
        self.totalFlightsDistance = totalFlightsDistance
        self.totalFlightsDuration = totalFlightsDuration
        self.lastFlight = lastFlight
    }

    // MARK: - Public Funcs
    public func isEqual(to other: MyFlightsState) -> Bool {
        return self.numberOfFlights == other.numberOfFlights
            && self.date == other.date
            && self.duration == other.duration
            && self.distance == other.distance
            && self.totalFlightsDistance == other.totalFlightsDistance
            && self.totalFlightsDuration == other.totalFlightsDuration
            && self.lastFlight == other.lastFlight
    }

    // MARK: - Copying Protocol
    public func copy() -> MyFlightsState {
        let copy = MyFlightsState(numberOfFlights: self.numberOfFlights,
                                  date: self.date,
                                  duration: self.duration,
                                  distance: self.distance,
                                  totalFlightsDuration: self.totalFlightsDuration,
                                  totalFlightsDistance: self.totalFlightsDistance,
                                  lastFlight: self.lastFlight)
        return copy
    }
}

// MARK: - MyFlightsViewModel
/// View Model for flights infos.
public final class MyFlightsViewModel: BaseViewModel<MyFlightsState> {
    // MARK: - Private Properties
    private var lastFlightViewModel: FlightDataViewModel? = CoreDataManager.shared.lastFlight()

    // MARK: - Private Enums
    private enum Constants {
        static let thumbnailSize: CGSize = CGSize(width: 80.0, height: 80.0)
    }

    // MARK: - Init
    override public init() {
        super.init()

        setupLastFlight()
        if let context = CoreDataManager.shared.currentContext {
            NotificationCenter.default
                .addObserver(self,
                             selector: #selector(managedObjectContextDidChange),
                             name: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                             object: context)
        }
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Private Funcs
private extension MyFlightsViewModel {
    /// Sets up flight view model for information display.
    func setupLastFlight() {
        updateAllFlightsOverview()
        lastFlightViewModel?.loadGutmaContent()
        lastFlightViewModel?.state.valueChanged = { [weak self] state in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            copy.duration = state.formattedDuration
            copy.distance = state.formattedDistance
            copy.date = state.date?.shortFormattedString
            strongSelf.state.set(copy)
        }
    }

    // Update flights overview data.
    func updateAllFlightsOverview() {
        CoreDataManager.shared.loadAllFlightDataState(completion: { [weak self] flights in
            guard let strongSelf = self else { return }

            let copy = strongSelf.state.value.copy()
            copy.numberOfFlights = flights.count
            let distance = Double(flights.reduce(0) { $0 + $1.distance })
            copy.totalFlightsDistance = UnitHelper.stringDistanceWithDouble(distance)
            let duration = Double(flights.reduce(0) { $0 + $1.duration })
            copy.totalFlightsDuration = duration.formattedHmsString ?? Style.dash
            strongSelf.state.set(copy)
        })
    }

    /// Listen CoreData's FlightDataModel add and remove to refresh view.
    @objc func managedObjectContextDidChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        // Check inserts.
        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>,
           inserts.contains(where: { $0 is FlightDataModel }) {
            updateAllFlightsOverview()
        }// Check deletes.
        else if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>,
                deletes.contains(where: { $0 is FlightDataModel }) {
            updateAllFlightsOverview()
        }
    }
}
