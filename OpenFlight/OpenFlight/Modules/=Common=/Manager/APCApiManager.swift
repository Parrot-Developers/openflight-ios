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

private extension ULogTag {
    static let tag = ULogTag(name: "APCApiManager")
}

// MARK: - APCApiManager
/// Manager that handles all methods relative to APC API.
public final class APCApiManager {
    // MARK: - Init
    public init() { }
}

// MARK: - Private Enums
private extension APCApiManager {
    /// APC Endpoints.
    enum EndPoints: String {
        case createTemporaryAccount = "/V4/account/tmp/create"
    }

    /// APC URLs.
    enum APCApiManagerURL {
        static let baseURL = "https://accounts-api.parrot.com"
    }

    /// APC parameters.
    enum Params {
        static let accountProvider = "APC"
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
                                                       _ error: Error?) -> Void) {
        // Builds the url.
        guard let url = buildAuthenticationUrl(with: EndPoints.createTemporaryAccount) else {
            completion(false,
                       nil,
                       AcademyApiServiceImpl.AcademyApiManagerError.badURL)
            return
        }

        // Creates the request.
        var request = URLRequest(url: url)
        request.httpMethod = RequestType.post
        request.setValue(RequestHeaderFields.formUrlEncoded, forHTTPHeaderField: RequestHeaderFields.contentType)

        temporarySession().dataTask(with: request) { data, _, error in
            guard error == nil else {
                completion(false, nil, error)
                return
            }

            guard let resultData = data else {
                completion(false,
                           nil,
                           AcademyApiServiceImpl.AcademyApiManagerError.noData)
                return
            }

            guard let apiResponse = ParserUtils.parse(AuthentificationResponse.self,
                                                      from: resultData) else {
                completion(false,
                           nil,
                           AcademyApiServiceImpl.AcademyApiManagerError.badData)
                return
            }

            self.updateGsdkUserAccount(token: apiResponse.apcToken)

            completion(apiResponse.apcAccountCreated,
                       apiResponse.apcToken,
                       nil)
        }.resume()
    }

    /// Set user account on gsdk.
    ///
    /// - Parameter token: the APC token to set
    func updateGsdkUserAccount(token: String?) {
        guard let token = token else {
            return
        }
        // User account update should be done on the main Thread.
        DispatchQueue.main.async {
            let userAccount = GroundSdk().getFacility(Facilities.userAccount)
            userAccount?.set(token: token)
        }
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
        config.httpAdditionalHeaders = [RequestHeaderFields.authorization: AuthenticationUtils.bearer(token: ""),
                                        RequestHeaderFields.callerId: ServicesConstants.xCallerId]
        config.addUserAgentHeader()
        return URLSession(configuration: config)
    }

    /// Returns an URL for authentication.
    ///
    /// - Parameters:
    ///    - endPoint: endPoint to reach
    ///    - params: params to add to the request
    func buildAuthenticationUrl(with endPoint: EndPoints, params: [String: String] = [:]) -> URL? {
        let token = AuthenticationUtils.token(params: params, apcKey: ServicesConstants.apcSecretKey)
        // TODO: Improve this with URLComponents and QueryItems
        return URL(string: "\(APCApiManagerURL.baseURL + endPoint.rawValue)?\(token)")
    }
}
