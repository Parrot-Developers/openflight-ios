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
import CoreLocation

/// View representing current drone position relative to user in a radar.
final class HUDRadarView: UIView, NibOwnerLoadable {

    // MARK: - Outlets
    @IBOutlet private weak var cardinalDirectionsBkgView: LDGradientView!
    @IBOutlet private weak var cardinalDirectionsView: CardinalDirectionsView!
    @IBOutlet private weak var cardinalContentView: UIView!
    @IBOutlet private weak var droneImageView: UIImageView!
    @IBOutlet private weak var droneBackgroundView: UIView!
    @IBOutlet private weak var topArrowView: SimpleArrowView!
    @IBOutlet private weak var leftArrowView: SimpleArrowView!
    @IBOutlet private weak var rightArrowView: SimpleArrowView!
    @IBOutlet private weak var droneImageViewCenterConstraint: NSLayoutConstraint!
    @IBOutlet private weak var cardinalContentHeightConstraint: NSLayoutConstraint!

    // MARK: - Internal Properties
    weak var state: HUDRadarState? {
        didSet {
            updateView()
        }
    }

    // MARK: - Private Properties
    private var currentUserHeading: Double = 0.0

    // MARK: - Private Enums
    private enum Constants {
        static let userHeadingChangeAcceptance: Double = 2.0
        static let userOrientedScopeAngle: Double = 135.0 // 3π/4
        static let warningLevelScopeAngle: Double = 45.0 // π/4
        static let gradientWidthDivider: CGFloat = 8.0
        static let gradientBorderColor: CGColor = UIColor.white.withAlphaComponent(0).cgColor
        static let gradientCentralColor: CGColor = UIColor.white.cgColor
        static let gradientStartX: CGFloat = 0.0
        static let gradientEndX: CGFloat = 1.0
        static let gradientY: CGFloat = 0.5
        static let droneBackgroundAlpha: CGFloat = 0.3
        static let cardinalDirectionsGradientStartColor: UIColor = .init(white: 0.3, alpha: 1)
        static let cardinalDirectionsGradientEndColor: UIColor = .init(white: 0.8, alpha: 1)
        static let cardinalDirecionsGradientAngle: CGFloat = 90
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Override Funcs
    override func layoutSubviews() {
        super.layoutSubviews()
        addGradientLayer()
    }
}

// MARK: - Private funcs
private extension HUDRadarView {
    /// Common init.
    func commonInit() {
        loadNibContent()
        topArrowView.orientation = .bottom
        leftArrowView.orientation = .left
        rightArrowView.orientation = .right
        leftArrowView.color = ColorName.errorColor.color
        rightArrowView.color = ColorName.errorColor.color
        updateColor(AlertLevel.none.radarColor)
        cardinalDirectionsBkgView.startColor = Constants.cardinalDirectionsGradientStartColor
        cardinalDirectionsBkgView.endColor = Constants.cardinalDirectionsGradientEndColor
        cardinalDirectionsBkgView.angle = Constants.cardinalDirecionsGradientAngle
        cardinalDirectionsBkgView.layer.cornerRadius = Style.smallCornerRadius
        cardinalDirectionsBkgView.clipsToBounds = true
    }

    /// Updates the view with current model.
    func updateView() {
        guard let state = state else {
            return
        }
        updateCardinalView(state: state)
        updateDroneOffset(state: state)
    }

    /// Updates the cardinal view component.
    func updateCardinalView(state: HUDRadarState) {
        guard let userHeading = state.userHeading else {
            return
        }
        let userHeadingChange = currentUserHeading - userHeading
        if abs(userHeadingChange) > Constants.userHeadingChangeAcceptance {
            cardinalDirectionsView.model.heading = userHeading
            currentUserHeading = userHeading
        }
    }

    /// Updates drone horizontal offset inside radar.
    func updateDroneOffset(state: HUDRadarState) {
        guard let droneCoordinate = state.droneLocation?.coordinate,
              let userCoordinate = state.userLocation?.coordinate,
              let userHeading = state.userHeading else {
            updateColor(AlertLevel.critical.radarColor)
            return
        }

        let deltaYaw = GeometryUtils.deltaYaw(fromLocation: userCoordinate,
                                              toLocation: droneCoordinate,
                                              withHeading: userHeading)

        let halfWidth = cardinalDirectionsView.bounds.width / 2.0
        let halfScope = Constants.userOrientedScopeAngle / 2.0
        let imageOffset = CGFloat(deltaYaw) * halfWidth / CGFloat(halfScope.toRadians())
        let margin: CGFloat = droneBackgroundView.bounds.width / 2
        droneImageViewCenterConstraint.constant = max(-bounds.width / 2 + margin, min(imageOffset, bounds.width / 2 - margin))

        let deltaYawDeg = Double(deltaYaw).toDegrees()

        let isConnected = state.droneConnectionState?.isConnected() == true
        droneBackgroundView.alphaWithEnabledState(isConnected)
        if isConnected {
            switch abs(deltaYawDeg) {
            case Constants.warningLevelScopeAngle...halfScope:
                updateColor(AlertLevel.warning.radarColor)
            case halfScope...:
                updateColor(AlertLevel.critical.radarColor)
            default:
                updateColor(AlertLevel.none.radarColor)
            }
        } else {
            updateColor(AlertLevel.none.color)
        }
        leftArrowView.isHidden = deltaYawDeg > Double(-halfScope)
        rightArrowView.isHidden = deltaYawDeg < Double(halfScope)
    }

    /// Adds a gradient layer to the view.
    func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        let gradientWidth = frame.width / Constants.gradientWidthDivider
        gradientLayer.frame = frame
        gradientLayer.colors = [Constants.gradientBorderColor,
                                Constants.gradientCentralColor,
                                Constants.gradientCentralColor,
                                Constants.gradientBorderColor]
        let startPoint = CGPoint(x: Constants.gradientStartX,
                                 y: Constants.gradientY)
        let endPoint = CGPoint(x: Constants.gradientEndX,
                               y: Constants.gradientY)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = [NSNumber(value: Double(Constants.gradientStartX)),
                                   NSNumber(value: Double(gradientWidth / frame.width)),
                                   NSNumber(value: Double((frame.width - gradientWidth)/frame.width)),
                                   NSNumber(value: Double(Constants.gradientEndX))]
        cardinalContentView.layer.mask = gradientLayer
    }

    /// Updates the color of the components with given color.
    ///
    /// - Parameters:
    ///    - color: color for the components
    func updateColor(_ color: UIColor) {
        droneBackgroundView.backgroundColor = color.withAlphaComponent(Constants.droneBackgroundAlpha)
    }
}
