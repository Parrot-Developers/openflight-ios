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

// MARK: - Protocols
protocol FlightPlanHistoryCellDelegate: AnyObject {
    /// Called when user taps the media view.
    ///
    /// - Parameters:
    ///     - flightModel: the current flight plan model
    ///     - action: action to perform
    func didTapOnMedia(flightModel: FlightPlanModel,
                       action: HistoryMediasActionType?)

    /// Called when user taps the resumeButton view.
    ///
    /// - Parameters:
    ///     - flightModel: the current flight plan model
    func didTapOnResume(flightModel: FlightPlanModel)
}

// MARK: - Public Enums
/// Stores different actions on the medias widget.
public enum HistoryMediasActionType {
    case report
    case end(url: URL)
    case disconnected
    case error // FIXME: Update spec to manage specifical errors
}

/// Flight Plan History TableView Cell.
final class FlightPlanHistoryTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var mediaContainerView: UIView!
    @IBOutlet private weak var photoCountContainerView: UIView!
    @IBOutlet private weak var resumeButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: FlightPlanHistoryCellDelegate?

    // MARK: - Private Properties
    private var flightModel: FlightPlanModel?
    private var currentAction: HistoryMediasActionType?

    // MARK: - Private Enums
    private enum Constants {
        static let buttonInset: CGFloat = 8.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        delegate = nil
        flightModel = nil
        currentAction = nil
    }
}

// MARK: - IBActions
private extension FlightPlanHistoryTableViewCell {
    @IBAction func resumeTouchedUpInside(_ sender: Any) {
        guard let flightModel = flightModel else { return }

        delegate?.didTapOnResume(flightModel: flightModel)
    }
}

// MARK: - Internal Funcs
extension FlightPlanHistoryTableViewCell {
    /// Inits the view.
    func initView() {
        contentView.backgroundColor = .clear
        backgroundColor = ColorName.white12.color
        dateLabel.makeUp()
    }

    /// Setup cell.
    ///
    /// - Parameters:
    ///     - flightModel: Flight Plan model
    ///     - mediasView: Flight Plan execution history view
    ///     - tableType: table type
    func setup(flightModel: FlightPlanModel,
               mediasView: HistoryMediasView?,
               tableType: HistoryTableType) {
        let isCompactCell = tableType == .miniHistory
        resumeButton.isHidden = isCompactCell
        setupExecutionButton(for: flightModel.state)
        dateLabel.text = flightModel.fomattedExecutionDate(isShort: isCompactCell)
        addPhotoCountView(flightModel: flightModel)
        self.flightModel = flightModel

        guard let view = mediasView?.view else {
            mediaContainerView.removeSubViews()
            mediaContainerView.isHidden = true
            return
        }

        self.currentAction = mediasView?.actionType
        addMediasView(with: view)
    }
}

// MARK: - Actions
private extension FlightPlanHistoryTableViewCell {
    /// Called when user presses media view.
    @objc func didTapOnMedia() {
        guard let flightModel = flightModel else { return }

        delegate?.didTapOnMedia(flightModel: flightModel,
                                action: currentAction)
    }
}

// MARK: - Private Funcs
private extension FlightPlanHistoryTableViewCell {
    /// Setup execution button.
    ///
    /// - Parameters:
    ///     - executionState: execution state of flight plan model
    func setupExecutionButton(for executionState: FlightPlanModel.FlightPlanState?) {
        resumeButton.isEnabled = executionState != .completed
        if executionState == .completed {
            resumeButton.makeup(color: .greenPea)
            resumeButton.setTitle(L10n.flightPlanRunCompleted, for: .normal)
            resumeButton.cornerRadiusedWith(backgroundColor: ColorName.clear.color,
                                            radius: Style.smallCornerRadius)
            resumeButton.contentEdgeInsets = UIEdgeInsets.zero
        } else {
            resumeButton.makeup(color: .orangePeel)
            resumeButton.setTitle(L10n.flightPlanRunResume, for: .normal)
            resumeButton.cornerRadiusedWith(backgroundColor: ColorName.orangePeel20.color,
                                            radius: Style.smallCornerRadius)
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
