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

// MARK: - AcademyApiManager
/// Manager that handles all methods relative to Academy API.
public class AcademyApiManager {
    // MARK: - Public Properties
    /// Returns base url for Academy API.
    public static var baseURL: String {
        return AcademyURL.prodBaseURL
    }

    // MARK: - Init
    public init() { }
}

// MARK: - Private Enums
private extension AcademyApiManager {
    /// Stores Academy base url.
    enum AcademyURL {
        static let prodBaseURL: String = "https://academy.parrot.com"
        static let mediaProdBaseURL: String = "\(prodBaseURL)/media/"
    }

    /// Stores Academy end points url.
    enum AcademyEndPoints {
        static let getChallenge = "/apiv1/4g/pairing/challenge?operation=associate"
        static let getDroneList = "/apiv1/drone/list"
        static let pairingAssociation = "/apiv1/4g/pairing"
    }
}

// MARK: - Public Enums
public extension AcademyApiManager {
    /// Stores academy API errors.
    enum AcademyApiManagerError: Int, Error {
        case unknownError
        case serverError
        case jsonError
        case badURL
        case badParameters
        case badImage
        case badResponseCode
        case badData
        case noData
        case authenticationError
        case accessDenied
        case preconditionFailed
    }
}

// MARK: - Private Funcs
private extension AcademyApiManager {
    /// Returns a custom URLSession to communicate with Academy API.
    func authSession() -> URLSession {
        var token: String = ""
        if UserInformation.current.token.isEmpty,
           !SecureKeyStorage.current.temporaryToken.isEmpty {
            // Use a temporary token if there is one and no real MyParrot account.
            token = SecureKeyStorage.current.temporaryToken
        } else {
            token = UserInformation.current.token
        }

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [RequestHeaderFields.authorization: AuthenticationUtils.bearer(token: token),
                                        RequestHeaderFields.contentType: RequestHeaderFields.appJson,
                                        RequestHeaderFields.xApiKey: ServicesConstants.academySecretKey]

        return URLSession(configuration: config)
    }
}

// MARK: - Public Funcs
public extension AcademyApiManager {
    /// Makes a GET request with custom parameters and returns a callback with the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func get(_ endpoint: String, session: URLSession, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let url = URL(string: AcademyApiManager.baseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        let task = session.dataTask(with: url) { data, response, error in
            self.treatResponse(data: data, response: response, error: error, completion: completion)
        }
        task.resume()
    }

    /// Makes a POST request with parameters and returns the response.
    ///
    /// - Parameters:
    ///    - endpoint: Academy API endpoint to reach.
    ///    - params: Parameters necessary for the request.
    ///    - session: Custom session.
    ///    - completion: Callback with the server response.
    func post(_ endpoint: String,
              params: [String: Any],
              session: URLSession,
              completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        guard let url = URL(string: AcademyApiManager.baseURL + endpoint) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.post
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            request.httpBody = httpBody
            session.dataTask(with: request) { data, response, error in
                self.treatResponse(data: data,
                                   response: response,
                                   error: error,
                                   completion: completion)
            }.resume()
        } catch let error {
            completion(nil, error)
        }
    }

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
                       completion: @escaping (_ jsonDict: Data?, _ error: Error?) -> Void) {
        guard error == nil else { return completion(nil, error) }

        guard let httpResponse = response as? HTTPURLResponse else {
            return completion(nil, AcademyApiManagerError.serverError)
        }

        var returnError: AcademyApiManagerError?

        switch httpResponse.statusCode {
        case 412:
            returnError = .preconditionFailed
        case 401:
            DispatchQueue.main.async {
                // UserInformation.current.disconnect() // TODO: Find a solution to disconnect user in FF
            }
            returnError = .authenticationError
        case 403:
            returnError = .accessDenied
        case 0..<200:
            returnError = .badResponseCode
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
}

// MARK: - Internal Funcs
extension AcademyApiManager {
    /// Performs the challenge request.
    ///
    /// - Parameters:
    ///     - completion: callback which returns challenge request result and error
    func performChallengeRequest(completion: @escaping ((String?, Error?) -> Void)) {
        let session = self.authSession()

        get(AcademyEndPoints.getChallenge, session: session) { data, error in
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

    /// Performs the pairing association request.
    ///
    /// - Parameters:
    ///     - token: the json string signed by the drone divided in three base64 part
    ///     - completion: callback which returns true if association is complete
    func performAssociationRequest(token: String, completion: @escaping ((Bool) -> Void)) {
        let session = self.authSession()
        guard let data = token.data(using: .utf8),
              let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(false)
            return
        }

        post(AcademyEndPoints.pairingAssociation, params: body, session: session) { data, error in
            guard error == nil,
                  data != nil else {
                completion(false)
                return
            }

            // Drone is succesfully paired to Academy.
            completion(true)
        }
    }

    /// Get paired drones list.
    ///
    /// - Parameters:
    ///     - completion: callback which returns the 4G paired drones list
    func performPairedDroneListRequest(completion: @escaping (([PairedDroneListResponse]?) -> Void)) {
        let session = self.authSession()

        get(AcademyEndPoints.getDroneList, session: session) { data, error in
            guard error == nil,
                  let responseData = data else {
                completion(nil)
                return
            }

            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode([PairedDroneListResponse].self, from: responseData)
                completion(response)
            } catch {
                completion(nil)
            }
        }
    }

    /// Unpairs current associated 4G drone.
    ///
    /// - Parameters:
    ///     - commonName: drone common name
    ///     - completion: callback which returns data and error
    func unpairDrone(commonName: String, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        let session = self.authSession()

        guard let url = URL(string: AcademyApiManager.baseURL + AcademyEndPoints.pairingAssociation + "/" + commonName) else {
            completion(nil, AcademyApiManagerError.badURL)
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = RequestType.delete
        request.setValue(RequestHeaderFields.appJson, forHTTPHeaderField: RequestHeaderFields.contentType)

        session.dataTask(with: request) { data, response, error in
            self.treatResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
}
