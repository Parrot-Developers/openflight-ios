//    Copyright (C) 2022 Parrot Drones SAS
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
import UIKit
import Combine

/// Constants for all external services.
enum ServicesConstants {
    /// ArcGIS license key.
    static let arcGisLicenseKey = "runtimelite,1000,rud8241485735,none,PM0RJAY3FL9BY7ZPM158"
    /// GroundSdk application key.
    static let groundSdkApplicationKey = "JwIwUsMiZ45VgLzo2V9v2MEsaOeiPaZ68VMOQk92"
    /// APC secret key.
    static let apcSecretKey = "MUxGw0eja9YbE8L&Gkhr-&We?MU98hD"
    /// Academy secret key.
    static let academySecretKey = "JwIwUsMiZ45VgLzo2V9v2MEsaOeiPaZ68VMOQk92"
    /// xCallerId
    static let xCallerId: String = "OpenFlight"
}

// MARK: - Protocol
protocol AcademyService: AcademyErrorService {
    // MARK: Properties
    /// Returns base url for Academy API.
    var baseURL: String { get }

    // MARK: Request
    /// Makes a GET request with custom parameters and returns a callback with the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - session: Custom session.
    ///    - completion: Callback with the result.
    func get(_ endpoint: String,
             session: URLSession?,
             completion: @escaping (Result<Data, Error>) -> Void)

    /// Makes a POST request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the result.
    func post(_ endpoint: String,
              params: [String: Any],
              session: URLSession?,
              completion: @escaping (Result<Data, Error>) -> Void)

    /// Makes a PUT request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the result.
    func put(_ endpoint: String,
             params: [String: Any],
             session: URLSession?,
             completion: @escaping (Result<Data, Error>) -> Void)

    /// Makes a DELETE request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the result.
    func delete(_ endpoint: String,
                session: URLSession?,
                completion: @escaping (Result<Data, Error>) -> Void)

    // MARK: Response handlers
    /// Handles the Data response with multiple verifications and returns the response in a Data object if it's correct.
    ///
    /// - Parameters:
    ///    - data: Data from the server.
    ///    - response: Response from the server.
    ///    - error: Error from the server.
    ///    - completion: Callback with the result.
    func treatResponse(data: Data?,
                       response: URLResponse?,
                       error: Error?,
                       completion: @escaping (Result<Data, Error>) -> Void)

    typealias BaseURL = AcademyServiceImpl.AcademyURL
    typealias RequestType = AuthenticationUtils.RequestType
    typealias HeaderField = AuthenticationUtils.RequestHeaderFields
    typealias Endpoint = AcademyServiceImpl.AcademyEndPoints
    typealias DroneEndpoint = AcademyServiceImpl.DroneAcademyEndPoints
    typealias Constants = AcademyServiceImpl.Constants


    // MARK: - FF

    /// Contains current Academy session
    var authCustomSession: URLSession? { get }

    /// Make a Delete request and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func deleteObject(_ endpoint: String,
                      session: URLSession?,
                      completion: @escaping (Result<Data, Error>) -> Void)

    /// Make a Post request with parameters in json format and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request in json format.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func postJsonObject<T: Encodable>(_ endpoint: String,
                        params: T,
                        session: URLSession?,
                        completion: @escaping (Result<Data, Error>) -> Void)
}

fileprivate extension String {
    static let tag = "pictor.myparrot.academy-api"
}

// MARK: - Implementation
/// Manager that handles all methods relative to Academy API.
class AcademyServiceImpl: AcademyService {

    /// Stores Academy base url.
    enum AcademyURL {
        public static let prodBaseURL: String = "https://academy.parrot.com"
        static let mediaProdBaseURL: String = "\(prodBaseURL)/media/"
    }

    /// Stores Academy end points url.
    enum DroneAcademyEndPoints: String, CaseIterable {
        case getChallenge = "/apiv1/4g/pairing/challenge?operation=associate"
        case getUnpairChallenge = "/apiv1/4g/pairing/challenge?operation=unpair_all"
        case getDroneList = "/apiv1/drone/list"
        case commonPairingEndpoint = "/apiv1/4g/pairing"
    }

    // MARK: FF Enum
    enum Constants {
        static let token: String = "token"
        static let clientId: String = "client_id"
        static let message: String = "message"
    }

    enum AcademyEndPoints: String {
        case avatar = "/apiv1/user/avatar"
        case flightGutma = "/apiv1/flight/%@/%d"
        case flightGutmaById = "/apiv1/flight/%d"

        /// FlightPlan Endpoints
        case flightPlanUrl = "/apiv1/flightplan/uploadurl"
        case flightPlansList = "/apiv1/flightplan/list"
        case flightPlanStatus = "/apiv1/flightplan/status/%@"
        case flightPlansData = "/apiv1/flightplan/%d"

        /// Project Endpoints
        case createProject = "/apiv1/flightplan/project"
        case deleteProject = "/apiv1/flightplan/project/%d"
        case projectList = "/apiv1/flightplan/project/list"

        /// Flight/Gutma Endpoint
        case flightUploadGutmaUrl = "/apiv1/gutma/uploadurl"
        case gutmaUploadStatus = "/apiv1/gutma/status/%@"
        case gutmaFlightList = "/apiv1/gutma/list"
        case gutmaFlight = "/apiv1/gutma/%d"

        /// FlightPlan Flight
        /// - parameters:
        ///     - flightplan_id
        ///     - flight_id
        case linkFPFlight = "/apiv1/flightplan/link/%d/run/%d"

        /// All user Data
        case allUserData = "/apiv1/user/alldata"

        /// Check if user exists
        case userExists = "/apiv1/user/"
    }

    // MARK: Private
    private let academyErrorSubject = CurrentValueSubject<Error?, Never>(nil)
    /// Queue to synchronize API calls
    private(set) var requestQueue: AcademyRequestQueue

    // MARK: Public
    public let academySession: AcademySessionProvider!

    // MARK: Academy Api Service Protocol Properties
    public var baseURL: String { AcademyURL.prodBaseURL }
    public var academyError: Error?
    public var academyErrorPublisher: AnyPublisher<Error?, Never> {
        academyErrorSubject.eraseToAnyPublisher()
    }

    // MARK: FF Properties
    var authCustomSession: URLSession? {
        return academySession.authCustomSession
    }

    // MARK: Init
    public init(requestQueue: AcademyRequestQueue,
                academySession: AcademySessionProvider) {
        self.requestQueue = requestQueue
        self.academySession = academySession
        self.academyErrorSubject.value = academyError
    }

    // MARK: Private
    /// If should manage access denied error from Academy
    /// - Parameters :
    ///     - urlResponse: HTTPURLResponse to verify
    /// - Returns :
    ///     - Bool indicates if should manage the error or not
    private func manageAccessDeniedError(_ urlResponse: HTTPURLResponse) -> Bool {
        return !AcademyService.DroneEndpoint.allCases.customContains(DroneAcademyEndPoints(rawValue: urlResponse.url?.path ?? ""))
    }
}

// MARK: - Academy Api Service Protocol
extension AcademyServiceImpl {
    // MARK: Request
    func get(_ endpoint: String,
             session: URLSession?,
             completion: @escaping (Result<Data, Error>) -> Void) {

        guard let session = session else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 GET \(url)")
        requestQueue.execute(URLRequest(url: url), session) { [weak self] data, response, error in
            guard let self = self else { return }
            self.treatResponse(data: data, response: response, error: error, completion: completion)
        }
    }

    func post(_ endpoint: String,
              params: [String: Any],
              session: URLSession?,
              completion: @escaping (Result<Data, Error>) -> Void) {

        guard let session = session else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 POST \(url)")
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.post
        request.setValue(AuthenticationUtils.RequestHeaderFields.appJson,
                         forHTTPHeaderField: AuthenticationUtils.RequestHeaderFields.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = httpBody

            requestQueue.execute(request, session) { [weak self] data, response, error in
                guard let self = self else { return }
                self.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func put(_ endpoint: String,
             params: [String: Any],
             session: URLSession?,
             completion: @escaping (Result<Data, Error>) -> Void) {

        guard let session = session else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 PUT \(url)")
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.put
        request.setValue(HeaderField.appJson, forHTTPHeaderField: HeaderField.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = httpBody
            requestQueue.execute(request, session) { [weak self] data, response, error in
                guard let self = self else { return }
                self.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func delete(_ endpoint: String,
                session: URLSession?,
                completion: @escaping (Result<Data, Error>) -> Void) {
        guard let session = session else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 DELETE \(url)")
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        request.setValue(HeaderField.appJson, forHTTPHeaderField: HeaderField.contentType)
        requestQueue.execute(request, session) { [weak self] data, response, error in
            guard let self = self else { return }
            self.treatResponse(data: data,
                               response: response,
                               error: error,
                               completion: completion)
        }
    }

    func deleteObject(_ endpoint: String,
                      session: URLSession?,
                      completion: @escaping (Result<Data, Error>) -> Void) {
        guard let session = session else {
            completion(.failure(AcademyError.cancelled))
            return
        }
        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 DELETE OBJECT \(url)")
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            self.treatResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    func postJsonObject<T: Encodable>(_ endpoint: String,
                        params: T,
                        session: URLSession?,
                        completion: @escaping (Result<Data, Error>) -> Void) {
        guard let session = session,
              let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🔵 POST JSON OBJECT \(url)")
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.post
        do {
            let jsonData = try JSONEncoder().encode(params)
            request.setValue(HeaderField.appJsonUtf8, forHTTPHeaderField: HeaderField.contentType)
            request.httpBody = jsonData
            session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                self.treatResponse(data: data, response: response, error: error, completion: completion)
            }.resume()
        } catch let error {
            completion(.failure(error))
        }
    }

    // MARK: Response Handler
    func treatResponse(data: Data?,
                       response: URLResponse?,
                       error: Error?,
                       completion: @escaping (Result<Data, Error>) -> Void) {
        guard error == nil else {
            PictorLogger.shared.e(.tag, "📡⬇️❌ AcademyAPI Response error: \(error?.localizedDescription ?? "")")
            return completion(.failure(AcademyError.unknownError))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            PictorLogger.shared.e(.tag, "📡⬇️❌ AcademyAPI Response error: server error")
            return completion(.failure(AcademyError.serverError))
        }

        var returnError: AcademyError?

        switch httpResponse.statusCode {
        case 412:
            returnError = .preconditionFailed
        case 401:
            returnError = .authenticationError
            academyErrorSubject.value = returnError
        case 403:
            returnError = .accessDenied
            if self.manageAccessDeniedError(httpResponse) {
                academyErrorSubject.value = returnError
            }
        case 404:
            returnError = .ressourceNotFound
        case 429:
            returnError = .tooManyRequests
            academyErrorSubject.value = returnError
        case 0..<200:
            returnError = .badResponseCode
        case 499..<527:
            returnError = .serverError
            academyErrorSubject.value = returnError
        case 300...1000:
            returnError = .badResponseCode
        default:
            returnError = nil
        }

        if let returnError = returnError {
            PictorLogger.shared.e(.tag, "📡⬇️🔴 AcademyAPI Code Response: \(returnError)")
            completion(.failure(returnError))
        } else if let responseData = data {
            completion(.success(responseData))
        } else {
            PictorLogger.shared.e(.tag, "📡⬇️🔴 AcademyAPI error: no data")
            completion(.failure(AcademyError.noData))
        }
    }
}

private extension AcademyServiceImpl {
    func dataLog(_ data: Data?) -> String {
        var result = "[NO DATA]"
        if let data = data {
            result = String(decoding: data, as: UTF8.self)
        }
        return result
    }
}
