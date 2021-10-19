//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Combine

class FlightDetailsExecutionsCell: UITableViewCell, NibReusable {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet weak var rightImageView: UIImageView!
    @IBOutlet weak var extraIcon: UIImageView!

    private var cancellables = Set<AnyCancellable>()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel.makeUp(with: .large, and: .defaultTextColor)
        statusLabel.makeUp(with: .small, and: .highlightColor)
        rightImageView.image = Asset.Common.Icons.icGreyChevron.image
            .withRenderingMode(.alwaysTemplate)
        rightImageView.tintColor = ColorName.defaultTextColor80.color
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.forEach { $0.cancel() }
    }

    func fill(with viewModel: FlightDetailsViewModel, at index: Int) {
        let execution = viewModel.flightPlans[index]
        titleLabel.text = execution.fomattedDate(isShort: false)

        Services.hub.ui.flightPlanUiStateProvider.uiStatePublisher(for: execution)
            .sink { [unowned self] stateUiParameters in
                statusLabel.text = stateUiParameters.historyStatusText
                statusLabel.textColor = stateUiParameters.historyStatusTextColor
                extraIcon.image = stateUiParameters.historyExtraIcon
                extraIcon.tintColor = stateUiParameters.historyExtraIconColor
                extraIcon.isHidden = stateUiParameters.historyExtraIcon == nil
            }
            .store(in: &cancellables)

        contentView.tapGesturePublisher
            .sink { _ in
                viewModel.showFlightDetailsExecution(at: index)
            }
            .store(in: &cancellables)
    }
}
