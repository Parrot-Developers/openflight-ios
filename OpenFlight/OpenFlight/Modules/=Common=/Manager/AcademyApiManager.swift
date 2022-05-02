//    Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk
import Combine

public protocol AcademyApiService: AnyObject {

    /// Returns base url for Academy API.
    var baseURL: String { get }

    /// Indicates if can perform authenticated Academy request or not
    var canPerformAcademyRequest: Bool { get set }

    /// Contains Error returned from Academy API call
    /// Authentication or Server Error
    var academyError: Error? { get set }

    /// Publisher of academyError
    var academyErrorPublisher: AnyPublisher<Error?, Never> { get }

    /// Cancel all current authenticated API calls
    /// To use when encountering an Authentification or a Server Academy Error
    func cancelAllCurrentTasks()

    /// Makes a DELETE request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func delete(_ endpoint: String,
                session: URLSession?,
                completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Makes a GET request with custom parameters and returns a callback with the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func get(_ endpoint: String,
             session: URLSession?,
             completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Makes a POST request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func post(_ endpoint: String,
              params: [String: Any],
              session: URLSession?,
              completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Makes a PUT request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func put(_ endpoint: String,
             params: [String: Any],
             session: URLSession?,
             completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Handles the Data response with multiple verifications and returns the response in a Data object if it's correct.
    ///
    /// - Parameters:
    ///    - data: Data from the server.
    ///    - response: Response from the server.
    ///    - error: Error from the server.
    ///    - completion: Callback with the server response.
    func treatResponse(data: Data?,
                       response: URLResponse?,
                       error: Error?,
                       completion: @escaping (_ jsonDict: Data?, _ error: Error?) -> Void)

    /// Gets paired drones list.
    ///
    /// - Parameters:
    ///    - completion: callback which returns the paired drones list
    func performPairedDroneListRequest(completion: @escaping (([AcademyPairedDrone]?) -> Void))

    /// Gets paired drones list.
    ///
    /// - Parameters:
    ///    - completion: callback which returns the paired drones list
    func getPairedDroneList(completion: @escaping (Result<[AcademyPairedDrone], Error>) -> Void)

    /// Performs the challenge request.
    ///
    /// - Parameters:
    ///     - action: create a challenge with our selected action (pair or unpair)
    ///     - completion: callback which returns challenge request result and error
    func performChallengeRequest(action: PairingAction,
                                 completion: @escaping ((String?, Error?) -> Void))

    /// Performs the pairing association request.
    ///
    /// - Parameters:
    ///     - token: the json string signed by the drone divided in three base64 part
    ///     - completion: callback which returns the result of the association process
    func performAssociationRequest(token: String,
                                   completion: @escaping ((Result<Bool, Error>) -> Void))

    /// Unpairs current associated 4G drone.
    ///
    /// - Parameters:
    ///     - commonName: drone common name
    ///     - completion: callback which returns data and error
    func unpairDrone(commonName: String,
                     completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Unpairs all users associated to the current drone except the authenticated one.
    ///
    /// - Parameters:
    ///     - token: the json string signed by the drone divided in three base64 part
    ///     - completion: callback which returns data and error
    func unpairAllUsers(token: String,
                        completion: @escaping (_ data: Data?, _ error: Error?) -> Void)

    /// Gets paired users count for a selected drone.
    ///
    /// - Parameters:
    ///     - commonName: drone common name
    ///     - completion: callback which returns number of paired users and a potential error
    func pairedUsersCount(commonName: String,
                          completion: @escaping (_ usersCount: Int?, _ error: Error?) -> Void)

    typealias ApiError = AcademyApiServiceImpl.AcademyApiManagerError
}

// MARK: - AcademyApiServiceImpl
/// Manager that handles all methods relative to Academy API.
public class AcademyApiServiceImpl: AcademyApiService {

    // MARK: - Properties

    public var baseURL: String {
        return AcademyURL.prodBaseURL
    }

    public var canPerformAcademyRequest: Bool = true

    public var academyError: Error?

    public var academyErrorPublisher: AnyPublisher<Error?, Never> { academyErrorSubject.eraseToAnyPublisher() }

    private let academyErrorSubject = CurrentValueSubject<Error?, Never>(nil)

    private let userService: UserService!
    public let academySession: AcademySessionProvider

    /// Queue to synchronize API calls
    private(set) var requestQueue: ApiRequestQueue

    /// Returns a custom URLSession to communicate with Academy API.
    private var authSession: URLSession? { academySession.authCustomSession }

    // MARK: - Init
    public init(requestQueue: ApiRequestQueue,
                academySession: AcademySessionProvider,
                userService: UserService) {
        self.requestQueue = requestQueue
        self.userService = userService
        self.academySession = academySession
        self.academyErrorSubject.value = academyError
    }
}

// MARK: - Enums
public extension AcademyApiServiceImpl {
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
}

// MARK: - Public Enums
public extension AcademyApiServiceImpl {
    /// Stores academy API errors.
    enum AcademyApiManagerError: Int, Error {
        case unknownError
        case serverError
        case jsonError
        case badURL
        case badParameters
        case badImage
        case ressourceNotFound
        case tooManyRequests
        case badResponseCode
        case badData
        case noData
        case authenticationError
        case accessDenied
        case preconditionFailed
        case cancelled

        var isError4xx: Bool {
            return [.preconditionFailed,
                    .authenticationError,
                    .accessDenied,
                    .ressourceNotFound]
                .contains(self)
        }

        static func error4xx(_ error: Error?) -> Self? {
            guard let error = error as? Self,
                  error.isError4xx else { return nil }
            return error
        }
    }
}

// MARK: - Private Funcs
private extension AcademyApiServiceImpl {

    /// If should manage access denied error from Academy
    /// - Parameters :
    ///     - urlResponse: HTTPURLResponse to verify
    /// - Returns :
    ///     - Bool indicates if should manage the error or not
    func manageAccessDeniedError(_ urlResponse: HTTPURLResponse) -> Bool {
        return !DroneAcademyEndPoints.allCases.customContains(DroneAcademyEndPoints(rawValue: urlResponse.url?.path ?? ""))
    }
}

// MARK: - Public Funcs
public extension AcademyApiServiceImpl {

    func cancelAllCurrentTasks() {
        requestQueue.cancelAcademyRequest()
    }

    func delete(_ endpoint: String,
                session: URLSession?,
                completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        // TODO: Change completion type to Result<Data, Error>

        guard let session = session, canPerformAcademyRequest else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)
        requestQueue.execute(request, session) { [weak self] data, response, error in
            self?.treatResponse(data: data,
                               response: response,
                               error: error,
                               completion: completion)
        }

    }

    func get(_ endpoint: String,
             session: URLSession?,
             completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {

        guard let session = session, canPerformAcademyRequest else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        requestQueue.execute(URLRequest(url: url), session) { [weak self] data, response, error in
            self?.treatResponse(data: data, response: response, error: error, completion: completion)
        }
    }

    func post(_ endpoint: String,
              params: [String: Any],
              session: URLSession?,
              completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {

        guard let session = session, canPerformAcademyRequest else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.post
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = httpBody

            requestQueue.execute(request, session) { [weak self] data, response, error in
                self?.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }
        } catch let error {
            completion(nil, error)
        }
    }

    func put(_ endpoint: String,
             params: [String: Any],
             session: URLSession?,
             completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {

        guard let session = session, canPerformAcademyRequest else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.put
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = httpBody
            requestQueue.execute(request, session) { [weak self] data, response, error in
                self?.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }
        } catch let error {
            completion(nil, error)
        }
    }

    func treatResponse(data: Data?,
                       response: URLResponse?,
                       error: Error?,
                       completion: @escaping (_ jsonDict: Data?, _ error: Error?) -> Void) {
        // TODO: Change competion type to Result<Data, Error>

        guard canPerformAcademyRequest else {
            return completion(nil, AcademyApiManagerError.cancelled)
        }

        guard error == nil else {
            ULog.e(.academyApiTag, "AcademyAPI Response error : \(error?.localizedDescription ?? "")")
            return completion(nil, AcademyApiManagerError.unknownError)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return completion(nil, AcademyApiManagerError.serverError)
        }

        var returnError: AcademyApiManagerError?

        switch httpResponse.statusCode {
        case 412:
            returnError = .preconditionFailed

        case 401:
            returnError = .authenticationError
            academyErrorSubject.value = returnError
            return completion(nil, returnError)

        case 403:
            returnError = .accessDenied

            if self.manageAccessDeniedError(httpResponse) {
                academyErrorSubject.value = returnError
                return completion(nil, returnError)
            }
        case 404:
            returnError = .ressourceNotFound

        case 429:
            returnError = .tooManyRequests
            academyErrorSubject.value = returnError
            return completion(nil, returnError)

        case 0..<200:
            returnError = .badResponseCode

        case 499..<527:
            returnError = .serverError
            academyErrorSubject.value = returnError
            return completion(nil, returnError)

        case 300...1000:
            returnError = .badResponseCode

        default:
            returnError = nil
        }

        if let strongReturnError = returnError {
            completion(nil, strongReturnError)
            return
        }

        if let responseData = data {
            completion(responseData, nil)
        } else {
            completion(nil, AcademyApiManagerError.badData)
        }
    }

    func performPairedDroneListRequest(completion: @escaping (([AcademyPairedDrone]?) -> Void)) {
        getPairedDroneList {
            switch $0 {
            case .success(let list):
                completion(list)
            case .failure:
                completion(nil)
            }
        }
    }

    func getPairedDroneList(completion: @escaping (Result<[AcademyPairedDrone], Error>) -> Void) {
        guard let session = authSession else {
            completion(.failure(AcademyApiManagerError.authenticationError))
            return
        }

        ULog.d(.academyApiTag, "🦜 getPairedDroneList: \(DroneAcademyEndPoints.getDroneList.rawValue)")
        get(DroneAcademyEndPoints.getDroneList.rawValue, session: session) { data, error in
            ULog.d(.academyApiTag, "🦜 getPairedDroneList - data: \(String(data: data ?? Data(), encoding: .utf8)), error: \(error)")
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let responseData = data else {
                completion(.failure(AcademyApiManagerError.noData))
                return
            }

            let decodedResponse = [AcademyPairedDrone].decode(responseData,
                                                              convertFromSnakeCase: false)
            completion(decodedResponse)
        }
    }

}

// MARK: - Internal Funcs
public extension AcademyApiServiceImpl {

    func performChallengeRequest(action: PairingAction, completion: @escaping ((String?, Error?) -> Void)) {
        guard let session = authSession else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }
        var endpoint = ""

        switch action {
        case .pairUser:
            endpoint = DroneAcademyEndPoints.getChallenge.rawValue

        case .unpairUser:
            endpoint = DroneAcademyEndPoints.getUnpairChallenge.rawValue
        }

        get(endpoint, session: session) { data, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let responseData = data,
                  let challenge = String(data: responseData, encoding: .utf8) else {
                completion(nil, AcademyApiManagerError.noData)
                return
            }

            completion(challenge, nil)
        }
    }

    func performAssociationRequest(token: String, completion: @escaping ((Result<Bool, Error>) -> Void)) {
        guard let session = authSession else {
            completion(.failure(AcademyApiManagerError.authenticationError))
            return
        }
        guard let data = token.data(using: .utf8),
              let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                  completion(.failure(AcademyApiManagerError.badParameters))
                  return
        }

        post(DroneAcademyEndPoints.commonPairingEndpoint.rawValue, params: body, session: session) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard data != nil else {
                completion(.failure(AcademyApiManagerError.noData))
                return
            }

            // Drone is succesfully paired to Academy.
            completion(.success(true))
        }
    }

    func unpairDrone(commonName: String, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let session = authSession else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + DroneAcademyEndPoints.commonPairingEndpoint.rawValue + "/" + commonName) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        session.dataTask(with: request) { [weak self] data, response, error in
            self?.treatResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    func unpairAllUsers(token: String, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let session = authSession else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let data = token.data(using: .utf8),
              let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(nil, AcademyApiManagerError.badParameters)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + DroneAcademyEndPoints.commonPairingEndpoint.rawValue) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = httpBody
            session.dataTask(with: request) { [weak self] data, response, error in
                self?.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }.resume()
        } catch let error {
            completion(nil, error)
        }
    }

    func pairedUsersCount(commonName: String,
                          completion: @escaping (_ usersCount: Int?, _ error: Error?) -> Void) {
        guard let session = authSession else {
            completion(nil, AcademyApiManagerError.cancelled)
            return
        }

        guard let url = URL(string: AcademyURL.prodBaseURL + DroneAcademyEndPoints.commonPairingEndpoint.rawValue + "/" + commonName) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.get
        request.setValue(RequestHeaderFields.appJson,
                         forHTTPHeaderField: RequestHeaderFields.contentType)

        session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completion(nil, error)
                return
            }

            guard let responseData = data else {
                completion(nil, nil)
                return
            }

            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(PairedUsersCountResponse.self, from: responseData)
                completion(response.usersCount, nil)
            } catch {
                completion(nil, nil)
            }
        }.resume()
    }
}
