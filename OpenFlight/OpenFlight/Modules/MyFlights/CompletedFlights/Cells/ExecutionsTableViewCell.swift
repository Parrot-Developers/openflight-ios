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
import Reusable

/// Execution TableView Cell.
/// NibLoadable is used for easier instanciation.
final class ExecutionsTableViewCell: UITableViewCell, NibReusable {
    @IBOutlet private weak var monthLabel: UILabel! {
        didSet {
            monthLabel.makeUp(with: .large, and: .defaultTextColor)
        }
    }
    @IBOutlet private weak var yearLabel: UILabel! {
        didSet {
            yearLabel.makeUp(and: .defaultTextColor80)
        }
    }

    @IBOutlet private weak var bgView: UIView! {
        didSet {
            bgView.backgroundColor = ColorName.white.color
            bgView.applyCornerRadius(Style.mediumCornerRadius)
        }
    }

    @IBOutlet private weak var dateLabel: UILabel! {
        didSet {
            dateLabel.makeUp(with: .large, and: .defaultTextColor)
        }
    }

    @IBOutlet private weak var statusLabel: UILabel! {
        didSet {
            statusLabel.makeUp(with: .large, and: .defaultTextColor)
        }
    }
    @IBOutlet weak var statusView: UIView!

    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var resumeButton: UIButton!
    @IBOutlet private weak var chevron: UIImageView!
    @IBOutlet private weak var mediaContainerView: UIView!
    @IBOutlet private weak var photoCountContainerView: UIView!

    @IBOutlet weak var bgViewleadingAnchor: NSLayoutConstraint!
    @IBOutlet weak var bgViewTrailingAnchor: NSLayoutConstraint!

    // MARK: - Private Properties
    private var flightModel: FlightPlanModel?
    private var currentAction: HistoryMediasActionType?

    // MARK: - Internal Properties
    weak var delegate: FlightPlanHistoryCellDelegate?

    // MARK: - Private Enums
    private enum Constants {
        static let buttonInset: CGFloat = 8.0
        static let backgroundViewLeftMargin: CGFloat = 60
        static let backgroundViewMarginMini: CGFloat = 12
        static let backgroundViewRightMargin: CGFloat = 15
        static let chevronWidthAnchor: CGFloat = 8
    }

    let chevronImage: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.image = Asset.Common.Icons.icGreyChevron.image
        image.tintColor = ColorName.defaultTextColor.color
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    override class func awakeFromNib() {
        super.awakeFromNib()

    }

    func updateViews(flightPlan: FlightPlanModel,
                     tableType: HistoryTableType,
                     showDate: Bool) {
        let isCompactCell = tableType == .miniHistory
        resumeButton.isHidden = isCompactCell
        chevronImage.isHidden = !isCompactCell
        monthLabel.isHidden = !(UIApplication.isLandscape || showDate) || isCompactCell
        yearLabel.isHidden = !(UIApplication.isLandscape || showDate) || isCompactCell
        durationLabel.isHidden = flightPlan.dataSetting?.estimations.duration?.formattedHmsString == nil || isCompactCell
        photoCountContainerView.isHidden = isCompactCell

        bgViewleadingAnchor.constant = isCompactCell ? Constants.backgroundViewMarginMini : Constants.backgroundViewLeftMargin
        bgViewTrailingAnchor.constant = isCompactCell ? Constants.backgroundViewMarginMini : Constants.backgroundViewRightMargin
    }
    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///    - flightPlan: Flight plan model
    ///    - showDate: Show flight date
    func configureCell(flightPlan: FlightPlanModel,
                       mediasView: HistoryMediasView?,
                       tableType: HistoryTableType,
                       showDate: Bool) {

        // Setup date section display.
        let isCompactCell = tableType == .miniHistory

        bgView.addSubview(chevronImage)
        NSLayoutConstraint.activate([
            chevronImage.widthAnchor.constraint(equalToConstant: Constants.chevronWidthAnchor),
            chevronImage.heightAnchor.constraint(equalToConstant: Constants.backgroundViewMarginMini),
            chevronImage.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -Constants.backgroundViewMarginMini),
            chevronImage.centerYAnchor.constraint(equalTo: bgView.centerYAnchor)
        ])

        monthLabel.alpha = showDate ? 1.0 : 0.0
        yearLabel.alpha = showDate ? 1.0 : 0.0

        durationLabel.text = flightPlan.dataSetting?.estimations.duration?.formattedHmsString
        durationLabel.makeUp(and: .defaultTextColor)
        if showDate {
            let date = flightPlan.lastUpdate
            monthLabel.text = date.month.capitalized
            yearLabel.text = date.year
        }
        dateLabel.text = flightPlan.fomattedExecutionDate(isShort: false)
        dateLabel.makeUp(with: .large, and: .defaultTextColor)

        let resumableStates: [FlightPlanModel.FlightPlanState] = [.flying, .stopped]
        if resumableStates.contains(flightPlan.state) {
            statusLabel.text = L10n.flightPlanRunStopped
            statusLabel.textColor = ColorName.warningColor.color
        } else {
            statusLabel.text = L10n.flightPlanRunCompleted
            statusLabel.textColor = ColorName.highlightColor.color
        }

        backgroundColor = ColorName.defaultBgcolor.color

        setupExecutionButton(for: flightPlan.state, type: tableType)
        dateLabel.text = flightPlan.fomattedExecutionDate(isShort: isCompactCell)
        addPhotoCountView(flightModel: flightPlan)
        self.flightModel = flightPlan

        updateViews(flightPlan: flightPlan, tableType: tableType, showDate: showDate)

        guard let view = mediasView?.view else {
            return
        }

        switch tableType {
        case .fullHistory:
            addMediasView(with: view)
        case .miniHistory:
            addMediasViewToStatusView(with: view)
        }
        self.currentAction = mediasView?.actionType
    }
}

private extension ExecutionsTableViewCell {
    /// Setup execution button.
    ///
    /// - Parameters:
    ///     - executionState: execution state of flight plan model
    func setupExecutionButton(for executionState: FlightPlanModel.FlightPlanState?, type: HistoryTableType) {
        let resumableStates: [FlightPlanModel.FlightPlanState] = [.flying, .stopped]
        resumeButton.isEnabled = resumableStates.contains(executionState)
        if !resumableStates.contains(executionState) {
            resumeButton.isHidden = true
            resumeButton.cornerRadiusedWith(backgroundColor: ColorName.white.color,
                                            radius: Style.largeCornerRadius)
        } else {
            resumeButton.isHidden = type == .miniHistory
            resumeButton.makeup()
            resumeButton.setTitle(L10n.flightPlanRunResume, for: .normal)
            resumeButton.cornerRadiusedWith(backgroundColor: ColorName.warningColor.color,
                                            radius: Style.largeCornerRadius)
            resumeButton.contentEdgeInsets = UIEdgeInsets(top: 0.0,
                                                          left: Constants.buttonInset,
                                                          bottom: 0.0,
                                                          right: Constants.buttonInset)
        }
    }

    /// Add medias view if it's needed.
    ///
    /// - Parameters:
    ///     - view: view to add
    func addMediasView(with view: UIView) {
        self.mediaContainerView.isHidden = false
        self.mediaContainerView.addWithConstraints(subview: view)
        let touchGesture = UITapGestureRecognizer(target: self,
                                                  action: #selector(didTapOnMedia))
        mediaContainerView.addGestureRecognizer(touchGesture)
    }

    /// Add medias view if it's needed.
    ///
    /// - Parameters:
    ///     - view: view to add
    func addMediasViewToStatusView(with view: UIView) {
        self.statusView.isHidden = false
        self.statusLabel.isHidden = true
        self.statusView.addWithConstraints(subview: view)
        let touchGesture = UITapGestureRecognizer(target: self,
                                                  action: #selector(didTapOnMedia))
        statusView.addGestureRecognizer(touchGesture)
    }

    /// Add photo count view for the corresponding execution.
    ///
    /// - Parameters:
    ///     - flightModel: The flight plan model
    func addPhotoCountView(flightModel: FlightPlanModel) {
        let view = FlightPlanPhotoCountView()
        view.setup(flightModel: flightModel)
        self.photoCountContainerView.addWithConstraints(subview: view)
    }

}

// MARK: - Actions
private extension ExecutionsTableViewCell {
    /// Called when user presses media view.
    @objc func didTapOnMedia() {
        guard let flightModel = flightModel else { return }

        delegate?.didTapOnMedia(flightModel: flightModel,
                                action: currentAction)
    }

    @IBAction func resumeButtonDidTouchUpInside(_ sender: Any) {
        guard let flightModel = flightModel else { return }
        delegate?.didTapOnResume(flightModel: flightModel)
    }
}
