//
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

class FlightExecutionDetailsFlightsCell: UITableViewCell, NibReusable {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet weak var rightImageView: UIImageView!

    private var tapGestureSubscriber: AnyCancellable?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    func setupUI() {
        titleLabel.makeUp(with: .large, and: .defaultTextColor)
        subtitleLabel.makeUp(with: .largeMedium, and: .defaultTextColor80)
        rightImageView.image = Asset.Common.Icons.icGreyChevron.image
            .withRenderingMode(.alwaysTemplate)
        rightImageView.tintColor = ColorName.defaultTextColor80.color
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tapGestureSubscriber?.cancel()
    }

    func fill(with viewModel: FlightExecutionDetailsFlightsCellModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        tapGestureSubscriber = contentView.tapGesturePublisher
            .sink { _ in
                viewModel.showFlight()
            }
    }
}
