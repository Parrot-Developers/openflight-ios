// Copyright (C) 2020 Parrot Drones SAS
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

extension FlightPlanManager {
    // MARK: - Internal Funcs
    /// Demo Content URLs.
    ///
    /// - Returns: FlightPlan data URL if available.
    /// TODO: remove this function.
    func demoContentURLs() -> [URL] {
        guard var documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            else {
                return []
        }
        documentsDirectoryURL.appendPathComponent(FlightPlanConstants.flightPlanDirectory)
        try? FileManager.default.createDirectory(atPath: documentsDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
        let fileNames = ["photog_9937", "sample_jemmapes", "sample_rennes"]
        var url: [URL] = []
        for name in fileNames {
            if let jsonUrl = Bundle.main.url(forResource: name, withExtension: "json") {
                let urlFinal = documentsDirectoryURL
                    .appendingPathComponent(name, isDirectory: false)
                    .appendingPathExtension("json")
                try? FileManager.default.copyItem(at: jsonUrl, to: urlFinal)
                url.append(urlFinal)
            }
        }
        return url
    }
}
