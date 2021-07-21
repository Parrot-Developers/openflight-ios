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
                mainColor: UIColor = ColorName.greenSpring.color,
                subColor: UIColor = ColorName.greenPea.color,
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
    init(withRunFlightPlanState state: RunFlightPlanState) {
        let percentString: String = (state.progress * 100).asPercent(maximumFractionDigits: 0)
        let distanceString: String = UnitHelper.stringDistanceWithDouble(state.distance,
                                                                         spacing: false)

        switch state.runState {
        case .playing:
            self.init(mainText: String(format: "%@・%@",
                                       percentString,
                                       distanceString),
                      progress: state.progress)
        case .paused:
            self.init(mainText: String(format: "%@・%@",
                                       percentString,
                                       distanceString),
                      mainColor: ColorName.orangePeel.color,
                      subColor: ColorName.orangePeel20.color,
                      progress: state.progress)
        case .stopped, .userStopped:
            if state.isAvailable {
                self.init(mainText: L10n.flightPlanInfoDroneReady)
            } else {
                if state.isConnected() {
                    self.init(mainText: state.unavailabilityReasons.errorText ?? L10n.error,
                              mainColor: ColorName.redTorch.color,
                              hasError: true)
                } else {
                    self.init(mainText: L10n.commonDroneNotConnected,
                              mainColor: ColorName.yellowSea.color,
                              hasError: true)
                }

            }
        case .uploading:
            self.init(mainText: L10n.flightPlanInfoUploading)
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
        topLeftLabel.makeUp(with: .regular)
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
