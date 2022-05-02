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

/// `String` Helpers for Regex matching.
extension String {

    /// Represents a Regex Match.
    ///
    /// `fullMatch` contains the full regex match while `groups` the regex's captured groups.
    ///
    /// - Remark:
    ///   Searching matches with regex `\(C\) (\d+) Parrot (.*) SAS`
    ///   to the string: `"Copyright (C) 2022 Parrot Drones SAS"
    ///   will returns `FullMatch` = `(C) 2022 Parrot Drones SAS`
    ///   and `groups`= `["2022", "Drones"]`
    struct RegexMatch {
        /// The full match.
        let fullMatch: String
        /// The captured groups (thanks to parentheses `()`).
        var groups = [String]()
    }

    /// Contains all `RegexMatch`es of a search.
    struct RegexResult {
        var matches = [RegexMatch]()
    }

    /// Returns the result of a regex search.
    ///
    /// - Parameter regexPattern: the regex pattern
    /// - Returns: the `RegexResult` of the search
    /// - Throws: an error if the regular expression can't be created
    ///
    /// ### Example ###
    /// ````
    /// let string = "Copyright (C) 2022 Parrot Drones SAS"
    /// let regex = #" \(C\) (\d+) Parrot (.*) SAS"#
    /// let searchResult = try string.search(regexPattern: regex)
    /// searchResult.matches
    ///     .map {
    ///         print("Full Match: \($0.fullMatch)")
    ///         print("Captured Groups: \($0.groups)")
    ///     }
    /// ````
    /// Will print:
    /// ````
    /// Full Match:  (C) 2022 Parrot Drones SAS
    /// Captured Groups: ["2022", "Drones"]
    /// ````
    func search(regexPattern: String) throws -> RegexResult {
        // Create the regex with the pattern.
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])
        // Get the range of the complete string.
        let range = NSRange(startIndex..., in: self)
        // Serach matches.
        let matchesResult = regex.matches(in: self, range: range)
        // Build the `RegexResult`from `NSTextCheckingResult.
        var regexResult = RegexResult()
        for matchResult in matchesResult {
            // Get the result's full match.
            guard let fullMatchRange = Range(matchResult.range, in: self) else { continue }
            var regexMatch = RegexMatch(fullMatch: String(self[fullMatchRange]))
            // Loop through captured groups if exist.
            for index in 1..<matchResult.numberOfRanges {
                if let groupRange = Range(matchResult.range(at: index), in: self) {
                    regexMatch.groups.append(String(self[groupRange]))
                }
            }
            regexResult.matches.append(regexMatch)
        }
        return regexResult
    }

    /// Returns the `String`s list matching the specified regex pattern.
    ///
    /// - Parameter regex: the regex pattern
    /// - Returns: the `[String]`matches of the search
    ///
    /// ### Example ###
    /// ````
    /// let string = "Pa2022ot Parr1ot Dro1234nes Paot SAS"
    /// let regex = #"\d+"#
    /// let stringsFound = string.matches(for: regex)
    /// print(stringsFound)
    /// ````
    /// Will print:
    /// ````
    /// ["2022", "1", "1234"]
    /// ````
    ///  - Remark: Unlike `search(regexPattern: String)`, this method returns only the 'full matches'.
    ///        This is a simpler way for basic regex without the need to capture groups.
    func matches(for regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let range = NSRange(self.startIndex..., in: self)
            let matches = regex.matches(in: self, range: range)
            return matches
                .compactMap { Range($0.range, in: self) }
                .map { String(self[$0]) }
        } catch {
            return []
        }
    }

    /// Returns the first match of the specified regex pattern.
    ///
    /// - Parameter regex: the regex pattern
    /// - Returns: the `String`or `nil` if nothing is found
    func firstMatch(for regex: String) -> String? { matches(for: regex).first }

    /// Returns the last match of the specified regex pattern.
    ///
    /// - Parameter regex: the regex pattern
    /// - Returns: the `String`or `nil` if nothing is found
    func lastMatch(for regex: String) -> String? { matches(for: regex).last }
}
