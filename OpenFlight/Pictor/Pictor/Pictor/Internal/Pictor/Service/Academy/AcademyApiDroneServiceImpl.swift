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
import Combine

fileprivate extension String {
    static let tag = "pictor.myparrot.academy-api.drone"
}

// MARK: - Implementation
final class AcademyApiDroneServiceImpl: AcademyApiDroneService {
    // MARK: Private Properties
    private var academyService: AcademyService

    // MARK: Public Properties
    var academyError: Error? { academyService.academyError }

    var academyErrorPublisher: AnyPublisher<Error?, Never> {
        academyService.academyErrorPublisher.eraseToAnyPublisher()
    }

    init(academyService: AcademyService) {
        self.academyService = academyService
    }

    func getPairedDroneList(completion: @escaping (Result<[AcademyDroneResponse], Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.authenticationError))
            return
        }

        PictorLogger.shared.i(.tag, "📡⬆️🛸🔵 getPairedDroneList: \(academyService.DroneEndpoint.getDroneList.rawValue)")
        academyService.get(academyService.DroneEndpoint.getDroneList.rawValue, session: session) { result in
            switch result {
            case .success(let data):
                let decodedResponse = [AcademyDroneResponse].decode(data,
                                                                    convertFromSnakeCase: false)
                PictorLogger.shared.i(.tag, "📡⬇️🛸🟢 getPairedDroneList - decoded response:\n\(decodedResponse)")
                completion(decodedResponse)
            case .failure(let error):
                PictorLogger.shared.e(.tag, "📡⬇️🛸🔴 getPairedDroneList error: \(error)")
                completion(.failure(error))
            }
        }
    }

    func performChallengeRequest(action: PairingAction, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.cancelled))
            return
        }
        var endpoint = ""

        switch action {
        case .pairUser:
            endpoint = academyService.DroneEndpoint.getChallenge.rawValue

        case .unpairUser:
            endpoint = academyService.DroneEndpoint.getUnpairChallenge.rawValue
        }

        academyService.get(endpoint, session: session) { result in
            switch result {
            case .success(let data):
                guard let challenge = String(data: data, encoding: .utf8) else {
                    completion(.failure(AcademyError.noData))
                    return
                }
                completion(.success(challenge))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func performAssociationRequest(token: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.authenticationError))
            return
        }
        guard let data = token.data(using: .utf8),
              let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(.failure(AcademyError.badParameters))
            return
        }

        academyService.post(academyService.DroneEndpoint.commonPairingEndpoint.rawValue,
                        params: body,
                        session: session) { result in
            switch result {
            case .success:
                // Drone is succesfully paired to Academy.
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func unpairDrone(commonName: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: academyService.BaseURL.prodBaseURL + academyService.DroneEndpoint.commonPairingEndpoint.rawValue + "/" + commonName) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = academyService.RequestType.delete
        request.setValue(academyService.HeaderField.appJson, forHTTPHeaderField: academyService.HeaderField.contentType)

        session.dataTask(with: request) { [weak self] data, response, error in
            self?.academyService.treatResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    func unpairAllUsers(token: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let data = token.data(using: .utf8),
              let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            completion(.failure(AcademyError.badParameters))
            return
        }

        guard let url = URL(string: academyService.BaseURL.prodBaseURL + academyService.DroneEndpoint.commonPairingEndpoint.rawValue) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = academyService.RequestType.delete
        request.setValue(academyService.HeaderField.appJson, forHTTPHeaderField: academyService.HeaderField.contentType)

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = httpBody
            session.dataTask(with: request) { [weak self] data, response, error in
                self?.academyService.treatResponse(data: data,
                                               response: response,
                                               error: error,
                                               completion: completion)
            }.resume()
        } catch let error {
            completion(.failure(error))
        }
    }

    func pairedUsersCount(commonName: String,
                          completion: @escaping (Result<Int?, Error>) -> Void) {
        guard let session = academyService.authCustomSession else {
            completion(.failure(AcademyError.cancelled))
            return
        }

        guard let url = URL(string: academyService.BaseURL.prodBaseURL + academyService.DroneEndpoint.commonPairingEndpoint.rawValue + "/" + commonName) else {
            completion(.failure(AcademyError.badURL))
            return
        }

        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = academyService.RequestType.get
        request.setValue(academyService.HeaderField.appJson,
                         forHTTPHeaderField: academyService.HeaderField.contentType)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let responseData = data else {
                completion(.success(nil))
                return
            }

            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(AcademyPairedUsersCountResponse.self, from: responseData)
                completion(.success(response.usersCount))
            } catch {
                completion(.failure(AcademyError.jsonError))
            }
        }.resume()
    }
}
