// Copyright (C) 2019 Parrot Drones SAS
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
import UIKit
import CoreLocation

// MARK: - Helpers for `FlightDataModel`.
extension FlightDataModel {
    /// Returns FlightDataState from FlightDataModel.
    func flightDataState() -> FlightDataState {
        var thumbnail: UIImage?
        if let thumb = self.thumbnail {
            thumbnail = UIImage(data: thumb)
        }
        return FlightDataState(placemark: nil,
                               location: CLLocation(latitude: self.latitude, longitude: self.longitude),
                               flightDescription: self.title,
                               date: self.date,
                               lastModified: self.lastModified,
                               duration: self.duration,
                               batteryConsumption: "",
                               distance: self.distance,
                               gutmaFileKey: self.gutmaFileKey,
                               thumbnail: thumbnail,
                               hasIssues: self.hasIssues,
                               checked: self.checked,
                               cloudStatus: self.cloudStatus)
    }

    /// Loads persisted gutma.
    func loadGutma() -> Gutma? {
        return self.gutma?.gutmaFile?.asGutma()
    }
}

// MARK: - Fetch helpers for `FlightDataModel`
extension FlightDataModel {
    /// Returns NSPredicate regarding value.
    ///
    /// - Parameters:
    ///     - sortValue: sort value
    static func fileKeyPredicate(sortValue: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@",
                           #keyPath(FlightDataModel.gutmaFileKey),
                           sortValue)
    }

    /// Returns descending date sorting NSFetchRequest.
    static func sortByDateRequest() -> NSFetchRequest<FlightDataModel> {
        let fetchRequest: NSFetchRequest<FlightDataModel> = FlightDataModel.fetchRequest()
        let sort = NSSortDescriptor(key: #keyPath(FlightDataModel.date), ascending: false)
        fetchRequest.sortDescriptors = [sort]
        return fetchRequest
    }
}
