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
protocol FlightPlanHistoryCellDelegate: class {
    /// Called when user taps the media view.
    ///
    /// - Parameters:
    ///     - fpExecution: the current flight plan execution
    ///     - action: action to perform
    func didTapOnMedia(fpExecution: FlightPlanExecution,
                       action: HistoryMediasActionType?)
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

    // MARK: - Internal Properties
    weak var delegate: FlightPlanHistoryCellDelegate?

    // MARK: - Private Properties
    private var fpExecution: FlightPlanExecution?
    private var currentAction: HistoryMediasActionType?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        delegate = nil
        fpExecution = nil
        currentAction = nil
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

    /// Setup cell. By default, progress is set to 1 (100%) and medias are hidden.
    ///
    /// - Parameters:
    ///     - fpExecution: Flight Plan execution
    ///     - mediasView: Flight Plan execution history view
    func setup(fpExecution: FlightPlanExecution?,
               mediasView: HistoryMediasView?) {
        guard let execution = fpExecution else { return }

        dateLabel.text = execution.executionDate
        addPhotoCountView(fpExecution: execution)
        self.fpExecution = execution

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
        guard let execution = fpExecution else { return }

        delegate?.didTapOnMedia(fpExecution: execution,
                                action: currentAction)
    }
}

// MARK: - Private Funcs
private extension FlightPlanHistoryTableViewCell {
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
    ///     - fpExecution: The flight plan execution
    func addPhotoCountView(fpExecution: FlightPlanExecution) {
        let view = FlightPlanPhotoCountView()
        view.setup(fpExecution: fpExecution)
        self.photoCountContainerView.addWithConstraints(subview: view)
    }
}
