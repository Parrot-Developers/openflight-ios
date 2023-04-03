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

internal extension String {
    static let apcApiManager = "pictor.apc_api_manager"
}

// MARK: - Internal Enums
final class APCApiManager {
    typealias RequestType = AuthenticationUtils.RequestType
    typealias HeaderField = AuthenticationUtils.RequestHeaderFields

    internal var baseURL: String {
        return APCApiManagerURL.baseURL
    }

    init() {}
}

// MARK: - Private Enums
fileprivate extension APCApiManager {
    /// APC Endpoints.
    enum EndPoints: String {
        case createTemporaryAccount = "/V4/account/tmp/create"
    }

    /// APC URLs.
    enum APCApiManagerURL {
        static let baseURL = "https://accounts-api.parrot.com"
    }

    /// APC constants.
    enum PrivateConstants {
        /// APC secret key.
        static let apcSecretKey: String = "g%2SW+m,cc9|eDQBgK:qTS2l=;[O~f@W"
        /// Caller Id for APC.
        static let xCallerId: String = "OpenFlight"
    }

    /// Model response of temporary creation account.
    struct AuthenticationResponse: Codable {
        // MARK: - Internal Properties
        var apcAccountCreated: Bool?
        var techMessage: String
        var apcToken: String?
        var academyAccountCreated: Bool?

        // MARK: - Coding Keys
        enum CodingKeys: String, CodingKey {
            case apcAccountCreated, techMessage, apcToken, academyAccountCreated
        }
    }
}


// MARK: - Internal Funcs
extension APCApiManager {

    /// Create a temporary APC account.
    ///
    /// - Parameters:
    ///     - completion: completion block which returns account creation status
    func createTemporaryAccount(completion: @escaping (_ isAccountCreated: Bool?,
                                                       _ token: String?,
                                                       _ error: PictorUserServiceError?) -> Void) {
        // Builds the url.
        guard let url = buildAuthenticationUrl(with: EndPoints.createTemporaryAccount) else {
            completion(false, nil, .badUrl)
            return
        }

        // Creates the request.
        var request = URLRequest(url: url)
        request.httpMethod = AuthenticationUtils.RequestType.post
        request.setValue(HeaderField.formUrlEncoded, forHTTPHeaderField: HeaderField.contentType)

        temporarySession().dataTask(with: request) { data, _, error in
            guard error == nil else {
                completion(false, nil, .serverError)
                return
            }

            guard let resultData = data else {
                completion(false, nil, .emptyResponse)
                return
            }

            guard let apiResponse = ParserUtils.parse(AuthenticationResponse.self,
                                                      from: resultData) else {
                completion(false, nil, .parsingIssue)
                return
            }

            completion(apiResponse.apcAccountCreated, apiResponse.apcToken, nil)
        }.resume()
    }
}

// MARK: - Private Funcs
private extension APCApiManager {
    /// Returns an URL session for APC API without token.
    /// Only use for temporary account creation.
    ///
    /// - Returns: An URL session.
    func temporarySession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [HeaderField.authorization: AuthenticationUtils.bearer(token: ""),
                                        HeaderField.callerId: PrivateConstants.xCallerId]
        config.addUserAgentHeader()
        return URLSession(configuration: config)
    }

    /// Returns an URL for authentication.
    ///
    /// - Parameters:
    ///    - endPoint: endPoint to reach
    ///    - params: params to add to the request
    func buildAuthenticationUrl(with endPoint: EndPoints, params: [String: String] = [:]) -> URL? {
        let tokenQueryItems = AuthenticationUtils.tokenQueryItems(params: params, apcKey: PrivateConstants.apcSecretKey)
        var urlComponents = URLComponents(string: "\(baseURL + endPoint.rawValue)")
        urlComponents?.queryItems = tokenQueryItems
        return urlComponents?.url
    }
}
