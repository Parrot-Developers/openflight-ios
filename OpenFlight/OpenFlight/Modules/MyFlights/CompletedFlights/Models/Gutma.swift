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

// MARK: - Gutma
/// This file was generated automatically regarding Sdk's gutma file.
/// Do not edit, use extensions.
public class Gutma: Codable {
    public var exchange: Exchange?
}

// MARK: - Exchange
public class Exchange: Codable {
    public var exchangeType: String?
    public var message: Message?

    enum CodingKeys: String, CodingKey {
        case exchangeType = "exchange_type"
        case message
    }
}

// MARK: - Message
public class Message: Codable {
    public var flightData: FlightData?
    public var file: File?
    public var flightLogging: FlightLogging?
    public var messageType: String?

    enum CodingKeys: String, CodingKey {
        case flightData = "flight_data"
        case file
        case flightLogging = "flight_logging"
        case messageType = "message_type"
    }
}

// MARK: - File
public class File: Codable {
    public var version, loggingType, filename: String?
    public var creationDtg: String?

    enum CodingKeys: String, CodingKey {
        case version
        case loggingType = "logging_type"
        case filename
        case creationDtg = "creation_dtg"
    }
}

// MARK: - FlightData
public class FlightData: Codable {
    public var aircraft: Aircraft?
    public var gcs: Gcs?
    public var payload: [Payload]?
    public var flightID: String?
    public var remoteflightID: Int?

    enum CodingKeys: String, CodingKey {
        case aircraft, gcs, payload
        case flightID = "flight_id"
        case remoteflightID
    }
}

// MARK: - Aircraft
public class Aircraft: Codable {
    public var serialNumber, model, hardwareVersion, firmwareVersion: String?
    public var motherboardVersion: String?

    enum CodingKeys: String, CodingKey {
        case serialNumber = "serial_number"
        case model
        case hardwareVersion = "hardware_version"
        case firmwareVersion = "firmware_version"
        case motherboardVersion = "motherboard_version"
    }
}

// MARK: - Gcs
public class Gcs: Codable {
    public var type, name: String?
}

// MARK: - Payload
public class Payload: Codable {
    public var firmwareVersion, hardwareVersion, payload, serialNumber: String?

    enum CodingKeys: String, CodingKey {
        case firmwareVersion = "firmware_version"
        case hardwareVersion = "hardware_version"
        case payload
        case serialNumber = "serial_number"
    }
}

// MARK: - FlightLogging
public class FlightLogging: Codable {
    public var altitudeSystem, loggingStartDtg: String?
    public var events: [Event]?
    public var flightLoggingKeys: [String]?
    public var flightLoggingItems: [[Double]]?

    enum CodingKeys: String, CodingKey {
        case altitudeSystem = "altitude_system"
        case loggingStartDtg = "logging_start_dtg"
        case events
        case flightLoggingKeys = "flight_logging_keys"
        case flightLoggingItems = "flight_logging_items"
    }
}

// MARK: - Event
public class Event: Codable {
    public var eventInfo, eventTimestamp: String?

    enum CodingKeys: String, CodingKey {
        case eventInfo = "event_info"
        case eventTimestamp = "event_timestamp"
    }
}
