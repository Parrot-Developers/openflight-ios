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

fileprivate extension String {
    static let jsonDecoderTag = "json.decoder"
    static let urlAwsUploadTag = "url.aws-upload"
}

/// Utility extension for `Array`.
extension Array {
    /// Returns true if an element T is in the current Array.
    ///
    /// - Parameters:
    ///     - element: array element to compare
    public func customContains<T>(_ element: T) -> Bool where T: Equatable {
        return !self.filter({$0 as? T == element}).isEmpty
    }
}

extension DateFormatter {
    // MARK: - Public Enums
    private enum Constants {
        static let apiDateFormat: String = "yyyy-MM-dd HH:mm:ss"
    }
    public static let apiDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.apiDateFormat
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
}

extension URL {

    /* Closure completion implementation */
    /// Used to upload data file to S3
    /// - Parameters:
    ///    - object  : Type of related object
    ///    - uploadUrl: S3 URL to use for Upload
    ///    - dataFile: file to upload
    ///    - completion  : callBack return the Result: success or failure
    public func uploadFileToS3<T>(_ object: T,
                                  _ dataFile: Data?,
                                  _ contentType: String? = nil,
                                  completion: @escaping (Result<Bool, Error>) -> Void) {

        let objectType = String(describing: type(of: object.self))
        guard let dataFile = dataFile else {
            PictorLogger.shared.e(.urlAwsUploadTag, "S3️⃣🔴 No Data in \(objectType) found to upload to s3")
            completion(.failure(AcademyError.badData))
            return
        }

        var request = URLRequest(url: self)
        request.httpMethod = AcademyService.RequestType.put
        request.httpBody = dataFile
        if let contentType = contentType {
            request.setValue(contentType, forHTTPHeaderField: AcademyService.HeaderField.contentType)
        }

        PictorLogger.shared.i(.urlAwsUploadTag, "S3️⃣⬆️ uploadFileToS3: \(objectType), uploadUrl: \(self)")
        // Start uploading
        URLSession.shared.dataTask(with: request) { (_, _, error) in

            if let error = error {
                PictorLogger.shared.i(.urlAwsUploadTag, "S3️⃣🔴 uploadFileToS3 error: \(error)")
                completion(.failure(error))
            } else {
                PictorLogger.shared.i(.urlAwsUploadTag, "S3️⃣🟢 uploadFileToS3: \(objectType) OK")
                completion(.success(true))
            }
        }.resume()
    }

    /* Async/Await implementation */
    @discardableResult
    func uploadFileToS3<T>(_ object: T,
                           dataFile: Data?) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            uploadFileToS3(object,
                           dataFile) { continuation.resume(with: $0) }
        }
    }
}

public extension Decodable {
    static func decode(_ data: Data,
                       usingDecoder decoder: JSONDecoder = JSONDecoder(),
                       convertFromSnakeCase: Bool = false,
                       replaceEmptyJsonByNullIfNeeded: Bool = false) -> Result<Self, Error> {
        do {
            // Date formatter
            decoder.dateDecodingStrategy = .formatted(DateFormatter.apiDateFormatter)

            if convertFromSnakeCase {
                decoder.keyDecodingStrategy = .convertFromSnakeCase
            }

            var dataToDecode = data
            // Handle empty brackets
            if replaceEmptyJsonByNullIfNeeded {
                dataToDecode = data.emptyJsonConvertedToNull
            }

            let object = try decoder.decode(self, from: dataToDecode)
            return .success(object)

        } catch {
            PictorLogger.shared.e(.jsonDecoderTag, "🔴 Error while decoding response - \(Self.self) -: \(error)\nResponse: \(String(data: data, encoding: .utf8) ?? "")")
            return .failure(error)
        }
    }
}

public extension Encodable {
    /// Encodes the Encodable structure/class into JSON data.
    ///
    ///  - Returns the encoded JSON data
    ///  - Throws an error in case of failure
    ///
    ///  - Note:
    ///     • Date strategy:  Default Parrot Cloud API Date format `.apiDateFormatter` is used.
    ///     • Key coding strategy:  Convert to snake case (e.g. Codable `modelId` property will be encoded as `model_id` key).
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.apiDateFormatter)
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(self)
    }

    /// Returns a Dictionary representation used as query parameters.
    var queryParameters: [String: Any] {
        // Encodes the Encodable into JSON data.
        guard let data = try? encode() else { return [:]}
        // Serialize JSON data into Swift Dictionary.
        return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) ?? [:]
    }
}

public extension Array where Element: Decodable {
    static func decode(_ data: Data,
                       usingDecoder decoder: JSONDecoder = JSONDecoder(),
                       replaceEmptyJsonByNullIfNeeded: Bool = false) -> Result<Self, Error> {
        do {
            decoder.dateDecodingStrategy = .formatted(DateFormatter.apiDateFormatter)
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            var dataToDecode = data
            // Handle empty brackets
            if replaceEmptyJsonByNullIfNeeded {
                dataToDecode = data.emptyJsonConvertedToNull
            }

            let object = try decoder.decode(self, from: dataToDecode)
            return .success(object)

        } catch {
            PictorLogger.shared.e(.jsonDecoderTag, "🔴 Error while decoding response - \(Self.self) -: \(error)\nResponse: \(String(data: data, encoding: .utf8) ?? "")")
            return .failure(error)
        }
    }
}

// MARK: - Workaround to fix cases where `{}` is returned instead of null
private extension String {
    var emptyJsonConvertedToNull: String {
        replacingOccurrences(of: "{}", with: "null")
    }
}

private extension Data {
    var emptyJsonConvertedToNull: Data {
        guard let string = String(data: self, encoding: .utf8) else { return self }
        return string.emptyJsonConvertedToNull.data(using: .utf8) ?? self
    }
}
