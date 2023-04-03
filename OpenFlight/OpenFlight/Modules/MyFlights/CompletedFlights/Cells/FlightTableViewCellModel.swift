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
import CoreLocation
import MapKit

/// A cell model describing a flights list table view row.
open class FlightTableViewCellModel {

    /// The flight name (placeholder if name is unavailable).
    private(set) var title: String
    /// The start time of the flight.
    private(set) var startTime: Date?
    /// The flight date formatted string.
    private(set) var formattedDate: String?
    /// The flight duration formatted string.
    private(set) var formattedDuration: String?
    /// The number of photos captured during flight.
    private(set) var photoCount: Int16
    /// The number of videos captured during flight.
    private(set) var videoCount: Int16
    /// The flight thumbnail.
    private(set) var thumbnail: UIImage
    /// Whether cell is selected.
    private(set) var isSelected: Bool = false

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - title: the flight title
    ///    - startTime: the start time of the flight
    ///    - formattedDate: the flight date formatted string
    ///    - formattedDuration: the flight duration formatted string
    ///    - photoCount: the number of photos captured during flight
    ///    - videoCount: the number of videos captured during flight
    ///    - thumbnail: the flight thumbnail
    ///    - isSelected: whether the cell is selected
    init(title: String,
         startTime: Date? = nil,
         formattedDate: String? = nil,
         formattedDuration: String? = nil,
         photoCount: Int16,
         videoCount: Int16,
         thumbnail: UIImage,
         isSelected: Bool) {
        self.title = title
        self.startTime = startTime
        self.formattedDate = formattedDate
        self.formattedDuration = formattedDuration
        self.photoCount = photoCount
        self.videoCount = videoCount
        self.thumbnail = thumbnail
        self.isSelected = isSelected
    }
}
