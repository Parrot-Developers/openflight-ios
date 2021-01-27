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

import UIKit

// MARK: - Internal Enums
/// Enum describing different live streaming state.
enum LiveStreamingWidgetTypes {
    case started
    case stopped
    case none

    /// Title for the current state.
    var title: String? {
        switch self {
        case .none:
            return L10n.liveStreamingConnect
        case .stopped:
            return L10n.commonStart
        default:
            return nil
        }
    }

    /// Button color for the current state.
    var buttonColor: UIColor? {
        switch self {
        case .none,
             .stopped:
            return ColorName.greenSpring20.color
        default:
            return nil
        }
    }

    /// Button image for the current state.
    var buttonImage: UIImage? {
        switch self {
        case .started:
            return Asset.Common.Icons.stop.image
        default:
            return nil
        }
    }

    /// Background color for the current state.
    var backgroundColor: UIColor? {
        switch self {
        case .started:
            return ColorName.redTorch25.color
        default:
            return .clear
        }
    }

    /// Background color for the current state.
    var borderColor: UIColor? {
        switch self {
        case .started:
            return ColorName.white.color
        default:
            return .clear
        }
    }

    /// Live icon for the current state.
    var liveIcon: UIImage? {
        switch self {
        case .started:
            return Asset.Settings.Quick.icLiveSharingActive.image
        default:
            return Asset.Settings.Quick.icLiveSharingInactive.image
        }
    }
}

/// Describes live streaming priority.
enum StreamingPriority: Int, CaseIterable {
    case qualityPriority
    case latencyPriority

    /// Defines default priority.
    static var defaultPriority: StreamingPriority = .qualityPriority

    /// Returns priority regarding index.
    ///
    /// - Parameters:
    ///     - index: current index
    static func type(at index: Int) -> StreamingPriority {
        guard index >= 0, index < StreamingPriority.allCases.count
            else { return StreamingPriority.defaultPriority }
        return StreamingPriority.allCases[index]
    }

    /// Provides priority title.
    var title: String {
        switch self {
        case .qualityPriority:
            return L10n.liveStreamingQualityPriority
        case .latencyPriority:
            return L10n.liveStreamingLatencyPriority
        }
    }
}

/// Enum describing each streaming url connection state.
enum LiveStreamingConnectionState {
    case connected
    case connect
    case connecting
    case error

    /// Description for the current connection state.
    var description: String? {
        switch self {
        case .error:
            return L10n.liveStreamingError
        default:
            return nil
        }
    }

    /// Button title for the current connection state.
    var buttonTitle: String? {
        switch self {
        case .connected:
            return L10n.connected
        case .connect:
            return L10n.liveStreamingConnect
        case .connecting:
            return L10n.connecting
        case .error:
            return L10n.commonRetry
        }
    }
}

/// Object which represents an url for RMTP Live streaming connection.
class UrlLiveStreaming: NSObject, NSCoding {
    // MARK: - Private Enums
    private enum Keys {
        static let labelKey = "label"
        static let urlKey = "url"
    }

    // MARK: - Internal Properties
    /// Facultative label.
    var label: String
    /// Url use to connect the stream to RMTP server.
    var url: String

    // MARK: - Init
    required convenience init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: Keys.urlKey) as? String,
            let label = coder.decodeObject(forKey: Keys.labelKey) as? String else {
                self.init(label: "", url: "")
                return
        }
        self.init(label: label, url: url)
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - label: facultative label description
    ///     - url: stream url
    init(label: String, url: String) {
        self.url = url
        self.label = label
    }

    // MARK: - Override Funcs
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? UrlLiveStreaming else {
            return false
        }
        return label == object.label
            && url == object.url
    }

    // MARK: - Internal Funcs
    /// Encodes the receiver.
    ///
    /// - Parameters:
    ///     - coder: current archiver
    func encode(with coder: NSCoder) {
        coder.encode(self.label, forKey: Keys.labelKey)
        coder.encode(self.url, forKey: Keys.urlKey)
    }
}
