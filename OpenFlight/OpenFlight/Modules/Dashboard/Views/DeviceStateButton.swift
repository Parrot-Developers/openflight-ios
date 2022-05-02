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

import UIKit
import Reusable

/// Custom view for an update button.
final class DeviceStateButton: UIButton, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var stateLabel: UILabel!
    @IBOutlet private weak var updateImageView: UIImageView!

    // MARK: - Publics Enums
    /// Stores several device states of the dashboard.
    enum Status {
        /// Disconnected state.
        case disconnected
        /// Not disconnected state.
        case notDisconnected
        /// Calibration required state.
        case calibrationRequired
        /// Calibration recommended state.
        case calibrationIsRecommended
        /// Update available state.
        case updateAvailable
        /// Update required state.
        case updateRequired

        fileprivate var backgroundColor: Color {
            switch self {
            case .calibrationIsRecommended,
                 .updateAvailable:
                return ColorName.warningColor.color
            case .calibrationRequired,
                 .updateRequired:
                return ColorName.errorColor.color
            case .disconnected:
                return ColorName.clear.color
            default:
                return ColorName.highlightColor.color
            }
        }

        fileprivate var leftImageTintColor: Color {
            switch self {
            case .updateAvailable,
                 .updateRequired,
                 .calibrationRequired,
                 .calibrationIsRecommended:
                return .white
            default:
                return ColorName.defaultTextColor.color
            }
        }

        fileprivate var textColor: Color {
            return self == .disconnected ? ColorName.disabledTextColor.color : ColorName.white.color
        }

        fileprivate var leftImage: UIImage? {
            switch self {
            case .updateAvailable,
                 .updateRequired:
                return Asset.Drone.iconDownload.image
            default:
                return nil
            }
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        initViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        initViews()
    }

    /// Initalizes views.
    private func initViews() {
        customCornered(corners: [.allCorners],
                       radius: Style.smallCornerRadius,
                       backgroundColor: .clear,
                       borderColor: .clear,
                       borderWidth: Style.noBorderWidth)
    }

    /// Sets up the title of the button.
    ///
    /// - Parameters:
    ///   - status: the button status
    ///   - title: the button title
    func update(with status: Status, title: String) {
        stateLabel.text = title
        stateLabel.textColor = status.textColor
        updateImageView.image = status.leftImage
        updateImageView.tintColor = status.leftImageTintColor
        updateImageView.isHidden = status.leftImage == nil
        backgroundColor = status.backgroundColor
        isUserInteractionEnabled = status.leftImage != nil
    }
}
