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

import GroundSdk

// MARK: - Enums
/// Enumeration of all different video states.
public enum VideoState: Int {
    case none
    case playing
    case paused
}

/// Common structure from gallery related states.

class GalleryContentState: DeviceConnectionState {
    // MARK: - Private Properties
    // Source type.
    var sourceType: GallerySourceType = .unknown {
        didSet {
            sourceWasUpdated()
        }
    }
    // Reference date so that we can force a state update just by changing it.
    var referenceDate: Date = Date()
    /// All medias list.
    var medias: [GalleryMedia] = [] {
        didSet {
            mediasWereUpdated()
        }
    }
    /// Available space, in giga bytes.
    var availableSpace: Double = 0.0
    /// Capacity, in giga bytes.
    var capacity: Double = 0.0
    /// Current downloading media item.
    var downloadingItem: MediaItem?
    /// Download status.
    var downloadStatus: MediaTaskStatus = .complete
    /// Download progress.
    var downloadProgress: Float = 0.0
    /// Is removing medias.
    var isRemoving: Bool = false
    /// Storage used, in giga bytes.
    var storageUsed: Double {
        let used = capacity - availableSpace
        return used >= 0.0 ? used : 0.0
    }
    /// Current vdeo duration.
    var videoDuration: TimeInterval = 0.0
    /// Current video position.
    var videoPosition: TimeInterval = 0.0
    /// Current video state.
    var videoState: VideoState?

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - availableSpace: available space, in giga bytes
    ///    - capacity: capacity, in giga bytes
    ///    - downloadingItem: downloading item
    ///    - downloadStatus: download status
    ///    - downloadProgress: download progress
    ///    - isRemoving: is removing
    ///    - medias: media list
    ///    - sourceType: source type
    ///    - referenceDate: reference date
    ///    - videoDuration: video duration
    ///    - videoPosition: video position
    ///    - videoState: video state
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  downloadingItem: MediaItem?,
                  downloadStatus: MediaTaskStatus,
                  downloadProgress: Float,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  sourceType: GallerySourceType,
                  referenceDate: Date,
                  videoDuration: TimeInterval,
                  videoPosition: TimeInterval,
                  videoState: VideoState?) {
        super.init(connectionState: connectionState)
        self.availableSpace = availableSpace
        self.capacity = capacity
        self.downloadingItem = downloadingItem
        self.downloadStatus = downloadStatus
        self.downloadProgress = downloadProgress
        self.isRemoving = isRemoving
        self.medias = medias
        self.sourceType = sourceType
        self.referenceDate = referenceDate
        self.videoDuration = videoDuration
        self.videoPosition = videoPosition
        self.videoState = videoState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let typedOther = other as? GalleryContentState else {
            return super.isEqual(to: other)
        }
        return super.isEqual(to: typedOther)
            && self.availableSpace.rounded(toPlaces: 1) == typedOther.availableSpace.rounded(toPlaces: 1)
            && self.capacity.rounded(toPlaces: 1) == typedOther.capacity.rounded(toPlaces: 1)
            && self.downloadingItem == typedOther.downloadingItem
            && self.downloadStatus == typedOther.downloadStatus
            && self.downloadProgress == typedOther.downloadProgress
            && self.isRemoving == typedOther.isRemoving
            && self.medias == typedOther.medias
            && self.sourceType == typedOther.sourceType
            && self.referenceDate == typedOther.referenceDate
            && self.videoDuration == typedOther.videoDuration
            && self.videoPosition == typedOther.videoPosition
            && self.videoState == typedOther.videoState
    }

    override func copy() -> Self {
        return Self(connectionState: self.connectionState,
                    availableSpace: self.availableSpace,
                    capacity: self.capacity,
                    downloadingItem: self.downloadingItem,
                    downloadStatus: self.downloadStatus,
                    downloadProgress: self.downloadProgress,
                    isRemoving: self.isRemoving,
                    medias: self.medias,
                    sourceType: self.sourceType,
                    referenceDate: self.referenceDate,
                    videoDuration: self.videoDuration,
                    videoPosition: self.videoPosition,
                    videoState: self.videoState)
    }

    /// Called when source is updated so that a subclass can sort / filter / etc.
    open func sourceWasUpdated() { }

    /// Called when medias are updated so that a subclass can sort / filter / etc.
    open func mediasWereUpdated() { }
}
