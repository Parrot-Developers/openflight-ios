//    Copyright (C) 2020 Parrot Drones SAS
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
import Combine

protocol FormattingNavigationDelegate: AnyObject {

    /// Informs of a close view request with optional toast message.
    ///
    /// - Parameters:
    ///    - message: the toast message to display (if any)
    ///    - duration: the toast message duration (relevant only if `message` is non-`nil`)
    func close(message: String?, duration: TimeInterval)
}

/// A view model for SD card formatting.
final class GalleryFormatSDCardViewModel: NSObject {

    /// The navigation delegate.
    weak var delegate: FormattingNavigationDelegate?

    // MARK: - Published Properties
    /// The formatting state.
    @Published private(set) var formattingState: StorageFormattingState = .unknown
    /// Whether formatting screen closing is allowed.
    @Published private(set) var canClose = true

    // MARK: - Private Properties
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The user storage service.
    private var userStorageService: UserStorageService!

    // MARK: - Internal Properties
    /// The selected formatting type.
    var selectedFormattingType: FormattingType = .quick

    // MARK: - Private Enums
    private enum Constants {
        static let partitioningMaxPercentage: Float = 10.0
        static let newPartitionMinPercentage: Float = 90.0
    }

    // MARK: - Init
    ///
    /// - Parameter userStorageService: the user storage service
    init(userStorageService: UserStorageService) {
        super.init()

        self.userStorageService = userStorageService
        listenToUserStorageService(userStorageService)
    }
}

// MARK: - Internal Funcs
extension GalleryFormatSDCardViewModel {

    /// Format SD card.
    ///
    /// - Returns: `true` if the format has been actually asked to the peripheral, `false` otherwise
    @discardableResult
    func format() -> Bool {
        userStorageService.format(formattingType: selectedFormattingType)
    }

    /// Listens to user storage service in order to update states accordingly.
    ///
    /// - Parameter userStorageService: the user storage service
    func listenToUserStorageService(_ userStorageService: UserStorageService) {
        userStorageService.formattingStatePublisher.sink { [weak self] state in
            guard let self = self else { return }
            self.canClose = !state.isRunning
            self.formattingState = state
        }
        .store(in: &cancellables)
    }

    /// Requests delegate to close view with optional toast message.
    ///
    /// - Parameters:
    ///    - message: the toast message to display (if any)
    ///    - duration: the toast message duration (relevant only if `message` is non-`nil`)
    func close(message: String? = nil, duration: TimeInterval = Style.longAnimationDuration) {
        delegate?.close(message: message, duration: duration)
    }
}

extension GalleryFormatSDCardViewModel {

    /// Returns the progress value to display according to ongoing formatting status.
    ///
    /// - Parameter status: the ongoing formatting status
    /// - Returns: the formatting progress to display
    func displayedProgress(for status: FormattingState) -> Float {
        let formattingProgressAsFloat: Float = Float(status.progress) / 100.0
        var currentShare: Float = 0.0
        var currentShareStart: Float = 0.0

        switch status.step {
        case .partitioning:
            currentShareStart = 0.0
            currentShare = Constants.partitioningMaxPercentage / 100.0
        case .clearingData:
            currentShareStart = Constants.partitioningMaxPercentage / 100.0
            currentShare = (Constants.newPartitionMinPercentage - Constants.partitioningMaxPercentage) / 100.0
        case .creatingFs:
            currentShareStart = Constants.newPartitionMinPercentage / 100.0
            currentShare = (100.0 - Constants.newPartitionMinPercentage) / 100.0
        }

        return currentShareStart + formattingProgressAsFloat * currentShare
    }
}
