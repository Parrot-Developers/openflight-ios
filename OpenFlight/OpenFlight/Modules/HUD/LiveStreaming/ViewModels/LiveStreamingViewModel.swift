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

/// State for `LiveStreamingViewModel`.

final class LiveStreamingState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// List of stored live streaming url.
    fileprivate(set) var streamingUrlList: [UrlLiveStreaming] = []

    /// Tells if an url has been added.
    var isNewUrlAdded: Bool = false

    // MARK: - Init
    required init() {}

    /// Init.
    ///
    /// - Parameters:
    ///    - streamingUrlList: list of stored live streaming url
    init(streamingUrlList: [UrlLiveStreaming]) {
        self.streamingUrlList = streamingUrlList
    }

    // MARK: - Equatable Protocol
    func isEqual(to other: LiveStreamingState) -> Bool {
        return self.streamingUrlList == other.streamingUrlList
    }

    // MARK: - Copying Protocol
    func copy() -> LiveStreamingState {
        let copy = LiveStreamingState(streamingUrlList: self.streamingUrlList)
        return copy
    }
}

/// View Model which manage live streaming panel datas.

final class LiveStreamingViewModel: BaseViewModel<LiveStreamingState> {
    // MARK: - Private Properties
    private var liveStreamingUrlListObserver: DefaultsDisposable?

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - stateDidUpdate: called when live streaming state is updated
    override init(stateDidUpdate: ((LiveStreamingState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenDefaults()
    }

    // MARK: - Deinit
    deinit {
        liveStreamingUrlListObserver?.dispose()
        liveStreamingUrlListObserver = nil
    }

    // TODO: To be continued
    // Waiting SDK
}

// MARK: - Private Funcs
private extension LiveStreamingViewModel {
    /// Starts watcher for user defaults.
    func listenDefaults() {
        /// Checks if deta from default is nil.
        if Defaults.liveStreamingUrlList == nil {
            initDefault()
        }

        liveStreamingUrlListObserver = Defaults.observe(\.liveStreamingUrlList) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                self?.updateLiveStreamingUrlList()
            }
        }
        updateLiveStreamingUrlList()
    }

    /// Update url list.
    func updateLiveStreamingUrlList() {
        let copy = state.value.copy()
        guard let data = Defaults.liveStreamingUrlList,
            let urlListExtracted = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [UrlLiveStreaming] else {
                return
        }
        copy.streamingUrlList = urlListExtracted.isEmpty ? [] : urlListExtracted
        state.set(copy)
    }

    /// Init default data for Live streaming.
    func initDefault() {
        do {
            // If the default data is nil, we need to init it.
            let urlList: [UrlLiveStreaming] = []
            let dataToSave = try NSKeyedArchiver.archivedData(withRootObject: urlList, requiringSecureCoding: false)
            // Update the live streaming url default.
            Defaults.liveStreamingUrlList = dataToSave
        } catch { }
    }
}
