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

import UIKit
import Reusable
import GroundSdk
import Combine

/// Settings choose channel cell.
final class SettingsChooseChannelCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var channelView: WifiChannelsOccupationGraphView!
    @IBOutlet private weak var gridView: WifiChannelsOccupationGridView!

    // MARK: - Private Properties
    private var viewModel: SettingsNetworkViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - viewModel: Settings network view model
    func configureCell(viewModel: SettingsNetworkViewModel) {
        self.viewModel = viewModel

        viewModel.$channelsOccupations
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.channelView.channelsOccupations = $0
                self.channelView.setNeedsDisplay()
                self.gridView.channelsOccupations = $0
            }
            .store(in: &cancellables)

        viewModel.isChannelsEnabledPublisher
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.gridView.alphaWithEnabledState($0)
                self.gridView.isUserInteractionEnabled = $0
            }
            .store(in: &cancellables)

        viewModel.$channelsOccupationIsEnabled
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.gridView.alphaWithEnabledState($0)
                self.gridView.isUserInteractionEnabled = $0
            }
            .store(in: &cancellables)

        viewModel.$currentChannel
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.gridView.currentChannel = $0
            }
            .store(in: &cancellables)

        viewModel.$channelUpdating
            .removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.gridView.currentChannelUpdating = $0
            }
            .store(in: &cancellables)

        gridView.delegate = self
        gridView.setNeedsDisplay()
    }
}

// MARK: - Wifi Channels Occupation Grid View Delegate
extension SettingsChooseChannelCell: WifiChannelsOccupationGridViewDelegate {
    func userDidSelectChannel(_ channel: WifiChannel) {
        viewModel?.changeChannel(channel)
    }
}
