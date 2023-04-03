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

/// Utilities to parse all kinds of data.

final class ParserUtils {

    // MARK: - Private Enums
    private enum Constants {
        static let dateFormat = "yyyy-MM-dd'T'HHmmssZ"
    }

    // MARK: - Private Funcs
    /// Custom encoder with specific settings.
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        encoder.dateEncodingStrategy = .formatted(formatter)
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    /// Custom decoder with specific settings.
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        decoder.dateDecodingStrategy = .formatted(formatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // MARK: - Public Funcs
    /// Method that try to decode and return the object in parameter.
    static func parse<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        do {
            let item = try decoder.decode(type, from: data)
            return item
        } catch {
            return nil
        }
    }

    /// Method that try to return a json object in an array.
    static func jsonDict<T: Encodable>(_ data: T) -> [String: Any]? {
        do {
            let jsonData = try encoder.encode(data)
            return try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as? [String: Any]
        } catch {
            return nil
        }
    }

    /// Method that tries to convert an object into a string.
    static func jsonString<T: Encodable>(_ data: T) -> String? {
        do {
            let jsonData = try JSONEncoder().encode(data)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            return nil
        }
    }
}
