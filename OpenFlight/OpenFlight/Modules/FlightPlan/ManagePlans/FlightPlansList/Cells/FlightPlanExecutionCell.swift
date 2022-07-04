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
import Combine

final class FlightPlanExecutionCell: MainTableViewCell, NibReusable {
    @IBOutlet private weak var cellBackgroundView: UIView!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var disclosureIndicator: UIImageView!
    @IBOutlet private weak var extraIcon: UIImageView!

    private var cancellables = Set<AnyCancellable>()

    private enum Constants {
        static let selectedBackgroundAlpha: CGFloat = 0.2
    }

    override var isHighlighted: Bool {
        didSet {
            self.titleLabel.isHighlighted = isHighlighted
            self.statusLabel.isHighlighted = isHighlighted
        }
    }

    // Configure selection style
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        let color: UIColor
        if selected {
            color = ColorName.highlightColor.color.withAlphaComponent(Constants.selectedBackgroundAlpha)
        } else {
            color = ColorName.white.color
        }
        cellBackgroundView.backgroundColor = color
        cellBackgroundView.directionalLayoutMargins = Layout.fileNavigationBarInnerMargins(isRegularSizeClass)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        cellBackgroundView.backgroundColor = ColorName.white.color
        cellBackgroundView.addShadow()

        titleLabel.makeUp(with: .large, and: .defaultTextColor)
        dateLabel.makeUp(with: .large, and: .disabledTextColor)
        statusLabel.makeUp(with: .small, and: .highlightColor)
        disclosureIndicator.tintColor = ColorName.disabledTextColor.color

        // Disable the default selection style
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        extraIcon.isHidden = true
    }

    /// Fills cell with execution details (use `customTitle` parameter content instead of
    /// actual execution title if provided).
    ///
    /// - Parameters:
    ///    - execution: the execution model
    ///    - customTitle: the title to use instead of `execution.customTitle` (if not `nil`).
    func fill(execution: FlightPlanModel, customTitle: String? = nil) {
        titleLabel.text = customTitle ?? execution.customTitle
        // TODO: Inject correclty after a refactor.
        dateLabel.text = Services.hub
            .flightPlan
            .manager
            .firstFlightFormattedDate(of: execution)

        Services.hub.ui.flightPlanUiStateProvider.uiStatePublisher(for: execution)
            .sink { [unowned self] stateUiParameters in
                statusLabel.text = stateUiParameters.historyStatusText
                statusLabel.textColor = stateUiParameters.historyStatusTextColor
                extraIcon.image = stateUiParameters.historyExtraIcon
                extraIcon.tintColor = stateUiParameters.historyExtraIconColor
                extraIcon.isHidden = stateUiParameters.historyExtraIcon == nil
            }
            .store(in: &cancellables)
    }
}
