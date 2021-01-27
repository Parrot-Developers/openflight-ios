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

import SwiftyUserDefaults

/// State for `LiveStreamingCellViewModel`.

final class LiveStreamingCellState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Current connection state.
    fileprivate(set) var liveStreamingConnectionState: LiveStreamingConnectionState = .connect
    /// Check if the url is encrypted.
    fileprivate(set) var isUrlEncrypted: Bool = false // TODO: Wait SDK

    // MARK: - Init
    required init() {}

    /// Init.
    ///
    /// - Parameters:
    ///    - liveStreamingConnectionState: current connection state
    ///    - isUrlEncrypted: tells if the url is encrypted
    init(liveStreamingConnectionState: LiveStreamingConnectionState,
         isUrlEncrypted: Bool) {
        self.liveStreamingConnectionState = liveStreamingConnectionState
        self.isUrlEncrypted = isUrlEncrypted
    }

    // MARK: - Equatable Protocol
    func isEqual(to other: LiveStreamingCellState) -> Bool {
        return self.liveStreamingConnectionState == other.liveStreamingConnectionState
            && self.isUrlEncrypted == other.isUrlEncrypted
    }

    // MARK: - Copying Protocol
    func copy() -> LiveStreamingCellState {
        let copy = LiveStreamingCellState(liveStreamingConnectionState: self.liveStreamingConnectionState,
                                          isUrlEncrypted: self.isUrlEncrypted)
        return copy
    }
}

/// View Model which manage live streaming cell data.

final class LiveStreamingCellViewModel: BaseViewModel<LiveStreamingCellState> {
    // MARK: - Internal Funcs
    /// Connect to the server.
    ///
    /// - Parameters:
    ///     - label: facultative descriptive label
    ///     - url: server url
    ///     - completion: callback which returns the result of the connection
    func connect(label: String?,
                 url: String?,
                 completion: @escaping (_ isRegistered: Bool) -> Void) {
        // FIXME: Add the url into Default only if succes.
        addUrl(label: label ?? "", url: url ?? "")
        // TODO: Waiting SDK for stream logic.
        completion(true)
    }

    /// Delete a stored url.
    ///
    /// - Parameters:
    ///     - label: facultative descriptive label to delete
    ///     - url: server url to delete
    func deleteUrl(label: String?, url: String?) {
        do {
            guard let data = Defaults.liveStreamingUrlList,
                var urlList = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UrlLiveStreaming] else {
                    return
            }
            let urlToRemove = UrlLiveStreaming(label: label ?? "", url: url ?? "")
            urlList.removeAll {
                $0 == urlToRemove
            }
            // Create the data.
            let dataToSave = try NSKeyedArchiver.archivedData(withRootObject: urlList, requiringSecureCoding: false)
            // Update default with the new url list.
            Defaults.liveStreamingUrlList = dataToSave
        } catch { }
    }

    /// Check if the url is registered.
    ///
    /// - Parameters:
    ///     - label: facultative descriptive label to delete
    ///     - url: server url to delete
    ///     - completion: callback which returns the result of the check
    func checkRegisteredUrl(label: String,
                            url: String,
                            completion: @escaping (_ isRegistered: Bool) -> Void) {
        do {
            guard let data = Defaults.liveStreamingUrlList,
                let urlList = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UrlLiveStreaming]
                else { return }

            let urlToCheck = UrlLiveStreaming(label: label, url: url)
            let isRegistered = urlList.contains { liveStreamUrl in
                return liveStreamUrl == urlToCheck
            }
            completion(isRegistered == true)
        } catch { }
    }
}

// MARK: - Private Funcs
private extension LiveStreamingCellViewModel {
    /// Add an url in the list.
    ///
    /// - Parameters:
    ///     - label: facultative descriptive label
    ///     - url: server url
    func addUrl(label: String, url: String) {
        checkRegisteredUrl(label: label, url: url, completion: { isRegistered in
            // Add the url in Default only if its not already registered.
            guard !isRegistered,
                let data = Defaults.liveStreamingUrlList else { return }
            do {
                let decodedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UrlLiveStreaming]
                var urlList = decodedData ?? []
                let urlToAdd = UrlLiveStreaming(label: label, url: url)
                urlList.append(urlToAdd)
                // Create the data with the list of url.
                let dataToSave = try NSKeyedArchiver.archivedData(withRootObject: urlList, requiringSecureCoding: false)
                // Update the live streaming url default.
                Defaults.liveStreamingUrlList = dataToSave
            } catch { }
        })
    }
}
