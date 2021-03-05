// Copyright (C) 2020 Parrot Drones SAS
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
import MapKit
import CoreData

/// State for `FlightDataViewModel`.

final public class FlightDataState: ViewModelState, EquatableState, Copying, FlightStateProtocol {
    // MARK: - Internal Properties
    /// Flight placemark.
    fileprivate(set) var placemark: CLPlacemark? {
        didSet {
            guard let addressDescription = placemark?.addressDescription
                else { return }
            flightDescription = addressDescription
        }
    }
    /// Flight placemark title.
    fileprivate(set) var flightDescription: String?
    /// Flight location.
    fileprivate(set) var location: CLLocation?
    /// Flight date.
    fileprivate(set) var date: Date?
    /// Flight last modification date.
    fileprivate(set) var lastModified: Date?
    /// Flight duration.
    public fileprivate(set) var duration: TimeInterval = 0.0
    /// Flight battery consumption.
    public fileprivate(set) var batteryConsumption: String = Style.dash
    /// Flight distance.
    fileprivate(set) var distance: Double = 0.0
    /// Flight file.
    fileprivate(set) var gutmaFileKey: String?
    /// Flight thumbnail.
    fileprivate(set) var thumbnail: UIImage?
    /// Whether flight has issues.
    fileprivate(set) var hasIssues: Bool = false
    /// Whether flight has been checked out.
    fileprivate(set) var checked: Bool = false

    // MARK: - Public Properties
    var title: String? {
        if let desc = flightDescription {
            return desc
        } else {
            return formattedPosition
        }
    }
    var cloudStatus: String?

    /// Formatted flight date.
    public var formattedDate: String? {
        return date?.formattedString(dateStyle: .full, timeStyle: .medium)
    }
    /// Returns position as string.
    public var formattedPosition: String {
        return location?.coordinate.coordinatesDescription ?? CLLocationCoordinate2D().coordinatesDescription
    }
    /// Returns duration as string.
    public var formattedDuration: String {
        return (duration.formattedHmsString) ?? Style.dash
    }
    /// Returns distance as string.
    var formattedDistance: String {
        return UnitHelper.stringDistanceWithDouble(distance)
    }
    /// Get the variable 'gutmaFileKey'.
    public var getGutmaFileKey: String? {
        return gutmaFileKey
    }

    /// Get the variable 'LastModified'.
    public var getLastModifiedDate: Date? {
        return lastModified
    }

    // MARK: - Init
    public required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - gutmaData: flight datas as Gutma
    ///    - gutmaFileKey: gutma flight ID
    ///    - lastModified: last modification date
    public init(gutmaData: Gutma, gutmaFileKey: String? = nil, lastModified: Date? = nil) {
        self.location = gutmaData.flightLocation
        self.date = gutmaData.startDate
        self.lastModified = lastModified
        self.duration = gutmaData.duration
        self.batteryConsumption = gutmaData.batteryConsumption
        self.distance = gutmaData.distance
        self.gutmaFileKey = gutmaData.flightId ?? gutmaFileKey ?? nil
        // TODO: check for issues in gutma data.
        self.hasIssues = false
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - placemark: flight placemark
    ///    - location: flight location
    ///    - date: flight date
    ///    - duration: flight duration
    ///    - batteryConsumption: flight batteryConsumption
    ///    - distance: flight distance
    ///    - gutmaFileKey: gutma file url
    ///    - thumbnail: flight thumbnail
    ///    - hasIssues: whether flight has issues
    ///    - checked: whether flight has been checked out
    ///    - cloudStatus: flight cloud status
    init(placemark: CLPlacemark?,
         location: CLLocation?,
         flightDescription: String?,
         date: Date?,
         lastModified: Date?,
         duration: TimeInterval,
         batteryConsumption: String,
         distance: Double,
         gutmaFileKey: String?,
         thumbnail: UIImage?,
         hasIssues: Bool,
         checked: Bool,
         cloudStatus: String?) {
        self.placemark = placemark
        self.flightDescription = flightDescription
        self.location = location
        self.date = date
        self.lastModified = lastModified
        self.duration = duration
        self.batteryConsumption = batteryConsumption
        self.distance = distance
        self.gutmaFileKey = gutmaFileKey
        self.thumbnail = thumbnail
        self.hasIssues = hasIssues
        self.checked = checked
        self.cloudStatus = cloudStatus
    }

    // MARK: - Public Funcs
    public func isEqual(to other: FlightDataState) -> Bool {
        // Compare only following data is enougth.
        return self.placemark == other.placemark
            && self.location == other.location
            && self.date == other.date
            && self.lastModified == other.lastModified
            && self.thumbnail == other.thumbnail
            && self.checked == other.checked
            && self.cloudStatus == other.cloudStatus
            && self.flightDescription == other.flightDescription
            && self.duration == other.duration
            && self.distance == other.distance
    }

    /// Update.
    ///
    /// - Parameters:
    ///    - gutmaData: flight datas as Gutma
    func update(gutmaData: Gutma) {
        self.duration = gutmaData.duration
        self.batteryConsumption = gutmaData.batteryConsumption
        self.distance = gutmaData.distance
    }

    // MARK: - Copying Protocol
    public func copy() -> FlightDataState {
        let place: CLPlacemark? = self.placemark?.copy() as? CLPlacemark
        let location: CLLocation? = self.location?.copy() as? CLLocation
        let copy = FlightDataState(placemark: place,
                                   location: location,
                                   flightDescription: flightDescription,
                                   date: date,
                                   lastModified: lastModified,
                                   duration: duration,
                                   batteryConsumption: batteryConsumption,
                                   distance: distance,
                                   gutmaFileKey: gutmaFileKey,
                                   thumbnail: thumbnail,
                                   hasIssues: hasIssues,
                                   checked: checked,
                                   cloudStatus: cloudStatus)
        return copy
    }
}

/// View model for flight data.
public final class FlightDataViewModel: BaseViewModel<FlightDataState>, FlightViewModelProtocol {
    // MARK: - Public Properties
    var gutma: Gutma?

    // MARK: - FlightViewModelProtocol Properties
    var location: CLLocationCoordinate2D? {
        return self.state.value.location?.coordinate
    }
    var shouldRequestThumbnail: Bool {
        guard self.state.value.thumbnail == nil
            else {
                return false
        }
        return true
    }
    var shouldRequestPlacemark: Bool {
        guard self.state.value.flightDescription == nil
            else {
                return false
        }
        return true
    }
    // Not used here because it may have to many points.
    var points: [CLLocationCoordinate2D] = []

    /// Get related Flight Plan view model(s).
    public var relatedFlightPlan: [FlightPlanViewModel] {
        loadGutmaContent()
        guard let flightId = self.gutma?.flightId else { return [] }

        // Retriveve related flight plans thanks to common executions.
        let relatedFlightPlansId = CoreDataManager.shared
            .executions(forFlightId: flightId)
            .compactMap { $0.flightPlanId }

        return CoreDataManager.shared
            .flightPlanStates(for: relatedFlightPlansId)
            .map { FlightPlanViewModel(state: $0) }
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - gutmaData: flight data as Gutma
    ///     - stateDidUpdate: completion block to notify state changes
    init(gutmaData: Gutma?, stateDidUpdate: ((FlightDataState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        if let data = gutmaData {
            self.gutma = data
            self.state.set(FlightDataState(gutmaData: data))
        }
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - state: flight data state
    public init(state: FlightDataState) {
        super.init(stateDidUpdate: nil)
        self.state.set(state)
    }

    // MARK: - Public Funcs
    /// Update placemark.
    ///
    /// - Parameters:
    ///     - placemark: new placemark
    func updatePlacemark(_ placemark: CLPlacemark?) {
        let copy = self.state.value.copy()
        copy.placemark = placemark
        self.state.set(copy)
        self.save()
    }

    /// Update flight title.
    ///
    /// - Parameters:
    ///     - title: flight title
    func updateTitle(_ title: String) {
        guard !title.isEmpty,
            self.state.value.flightDescription != title
            else {
                return
        }
        let copy = self.state.value.copy()
        copy.flightDescription = title
        self.state.set(copy)
        save()
    }

    /// Remove flight data.
    func removeFlight() {
        loadGutmaContent()
        if let flightId = self.gutma?.exchange?.message?.flightData?.remoteflightID,
           let account = AccountManager.shared.currentAccount {
            // Remote remove if exists.
            account.removeSynchronizedFlight(flightId: flightId,
                                             completion: { _, _ in })
        }
        // Local remove, regardless of the sync result to prevent from network issues.
        CoreDataManager.shared.removeFlight(for: self.state.value.gutmaFileKey)
    }

    /// Load all flight data from gutma file.
    func loadGutmaContent() {
        guard let gutmaFileKey = self.state.value.gutmaFileKey,
            self.gutma == nil
            else {
                return
        }
        if let persistedGutma = CoreDataManager.shared.gutma(for: gutmaFileKey) {
            self.gutma = persistedGutma
            let state = FlightDataState(gutmaData: persistedGutma)
            // Keep extra (requested) data.
            state.thumbnail = self.state.value.thumbnail
            state.flightDescription = self.state.value.flightDescription
            self.state.set(state)
        }
    }

    /// Persist state data.
    func save() {
        CoreDataManager.shared.saveOrUpdate(state: self.state.value)
    }

    // MARK: - Flight View Model Protocol
    /// Update thumbnail.
    ///
    /// - Parameters:
    ///     - image: new thumbnail image
    func updateThumbnail(_ image: UIImage?) {
        guard let image = image else { return }
        let copy = self.state.value.copy()
        copy.thumbnail = image
        DispatchQueue.main.async {
            self.state.set(copy)
            self.save()
        }
    }
}
