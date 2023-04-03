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
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "JSONDecoder")
}

public extension Decodable {
    static func decode(_ data: Data,
                       usingDecoder decoder: JSONDecoder = JSONDecoder(),
                       convertFromSnakeCase: Bool = false,
                       dateFormatter: DateFormatter = DateFormatter.apiDateFormatter,
                       replaceEmptyJsonByNullIfNeeded: Bool = false) -> Result<Self, Error> {
        do {
            // Date formatter
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            // TODO: Update all `Codable` to always use `convertFromSnakeCase`
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
            ULog.e(.tag, "Error while decoding response - \(Self.self) -: \(error)\nResponse: \(String(data: data, encoding: .utf8) ?? "")")
            return .failure(error)
        }
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
            ULog.e(.tag, "Error while decoding response - \(Self.self) -: \(error)\nResponse: \(String(data: data, encoding: .utf8) ?? "")")
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
