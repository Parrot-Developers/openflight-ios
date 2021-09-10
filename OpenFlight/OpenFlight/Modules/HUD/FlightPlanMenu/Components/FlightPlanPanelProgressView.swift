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

public struct FlightPlanPanelProgressInfo {
    public init(runState: FlightPlanRunningState, progress: Double) {
        self.runState = runState
        self.progress = progress
    }

    var runState: FlightPlanRunningState
    var progress: Double

}

// MARK: Public Structs
/// Model for Flight Plan panel progress view display.
public struct FlightPlanPanelProgressModel {
    var mainText: String
    var mainColor: UIColor
    var subColor: UIColor
    var progress: Double
    var hasError: Bool

    /// Init.
    ///
    /// - Parameters:
    ///    - mainText: text displayed at the top left of the progress bar
    ///    - mainColor: main color (text and progress)
    ///    - subColor: sub color (track)
    ///    - progress: current progress
    ///    - hasError: whether there is an ongoing error (hides progress bar)
    public init(mainText: String = "-",
                mainColor: UIColor = ColorName.highlightColor.color,
                subColor: UIColor = ColorName.whiteAlbescent.color,
                progress: Double = 0.0,
                hasError: Bool = false) {
        self.mainText = mainText
        self.mainColor = mainColor
        self.subColor = subColor
        self.progress = progress
        self.hasError = hasError
    }

    /// Init with `RunFlightPlanState`.
    ///
    /// - Parameters:
    ///    - state: Flight Plan's run state
    init(runState: FlightPlanRunningState,
         statMachine: FlightPlanStateMachineState,
         progress: Double,
         distance: Double) {
        let percentString: String = (progress * 100).asPercent(maximumFractionDigits: 0)
        let distanceString: String = UnitHelper.stringDistanceWithDouble(distance,
                                                                         spacing: false)

        switch statMachine {
        case .flying:
            switch runState {
            case let .playing(droneConnected, _, rth):
                if rth {
                    self.init(mainText: L10n.commonReturnHome,
                              mainColor: ColorName.greySilver.color,
                              subColor: ColorName.whiteAlbescent.color,
                              progress: 1.0)
                } else {
                    self.init(mainText: String(format: "%@・%@",
                                               percentString,
                                               distanceString),
                              mainColor: droneConnected ? ColorName.highlightColor.color : ColorName.defaultIconColor.color,
                              subColor: ColorName.whiteAlbescent.color,
                              progress: progress)
                }
            case .paused:
                self.init(mainText: L10n.flightPlanAlertStoppedAt(String(format: "%@・%@",
                                                                         percentString,
                                                                         distanceString)),
                          mainColor: ColorName.warningColor.color,
                          subColor: ColorName.whiteAlbescent.color,
                          progress: progress)
            default:
                self.init(mainText: "")
            }
        case .startedNotFlying:
            self.init(mainText: L10n.flightPlanInfoUploading)
        case .end:
            self.init(mainText: "")
        case let .resumable(_, startAvailability),
             let .editable(_, startAvailability):
            switch startAvailability {
            case .available:
                self.init(mainText: L10n.flightPlanInfoDroneReady)
            case let .unavailable(reason):
                switch reason {
                case .droneDisconnected:
                    self.init(mainText: L10n.commonDroneNotConnected,
                              mainColor: ColorName.redTorch.color,
                              hasError: true)
                case let .pilotingItfUnavailable(reasons):
                    self.init(mainText: reasons.errorText ?? L10n.error,
                              mainColor: ColorName.redTorch.color,
                              hasError: true)
                }
            case .alreadyRunning:
                self.init(mainText: "")
            }
        case .machineStarted, .initialized:
            self.init(mainText: "")
        }
    }
}

/// Displays a progress view inside Flight Plan's panel.
public final class FlightPlanPanelProgressView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var topLeftLabel: UILabel!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var extraViewsStackView: UIStackView!

    // MARK: - Public Properties
    public var model: FlightPlanPanelProgressModel = FlightPlanPanelProgressModel() {
        didSet {
            fill(with: model)
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonInitFlightPlanPanelProgressView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.commonInitFlightPlanPanelProgressView()
    }

    // MARK: - Public Funcs
    /// Adds extra autonomous views to the top right of the progress bar.
    /// Set with an empty array to clear.
    ///
    /// - Parameters:
    ///    - extraViews: array of views to add
    public func setExtraViews(_ extraViews: [UIView]) {
        extraViewsStackView.safelyRemoveArrangedSubviews(deactivateConstraint: false)
        extraViews.forEach { extraViewsStackView.addArrangedSubview($0) }
    }
}

// MARK: - Private Funcs
private extension FlightPlanPanelProgressView {
    /// Common init.
    func commonInitFlightPlanPanelProgressView() {
        self.loadNibContent()
        topLeftLabel.makeUp()
    }

    /// Fills up the view with given model.
    ///
    /// - Parameters:
    ///    - model: model for view
    func fill(with model: FlightPlanPanelProgressModel) {
        topLeftLabel.text = model.mainText
        topLeftLabel.textColor = model.mainColor
        progressView.tintColor = model.mainColor
        progressView.trackTintColor = model.subColor
        progressView.progress = Float(model.progress)
        progressView.isHidden = model.hasError
    }
}
