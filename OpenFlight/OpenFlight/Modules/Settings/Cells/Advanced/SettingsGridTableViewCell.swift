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

// MARK: - Protocol
/// Settings grid action view delegate.
protocol SettingsGridActionViewDelegate: AnyObject {
    /// Notifies when user is dragging the view.
    func userIsDragging(_ isDragging: Bool)
}

/// Manages drone gesture and display.
class SettingsGridActionView: UIView {
    // MARK: - Outlets
    @IBOutlet private weak var positionView: UIView! {
        didSet {
            positionView.backgroundColor = ColorName.white20.color
        }
    }
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var droneImage: UIImageView!
    @IBOutlet private weak var heightLabel: UILabel! {
        didSet {
            heightLabel.makeUp(with: .large, and: .white50)
        }
    }
    @IBOutlet private weak var distanceLabel: UILabel! {
        didSet {
            distanceLabel.makeUp(with: .large, and: .white50)
        }
    }

    // MARK: - Private Properties
    private weak var delegate: SettingsGridActionViewDelegate?
    private var dashedLinePath = UIBezierPath()
    private var droneHalfWidth: CGFloat = 0.0
    private var userTopLimit: CGFloat = 0.0
    private var userLeftLimit: CGFloat = 0.0
    private var maxAltitude: Double {
        return viewModel?.state.value.maxAltitude ?? GeofencePreset.maxAltitude
    }
    private var maxDistance: Double {
        return viewModel?.state.value.maxDistance ?? GeofencePreset.maxDistance
    }
    private var minAltitude: Double {
        return viewModel?.state.value.minAltitude ?? GeofencePreset.minAltitude
    }
    private var minDistance: Double {
        return viewModel?.state.value.minDistance ?? GeofencePreset.minDistance
    }
    private var viewModel: GeofenceViewModel?

    // MARK: - Private Enums
    private enum Constants {
        static let margin: CGFloat = 8.0
        static let labelSize: CGSize = CGSize(width: 100.0, height: 25.0)
        static let dashedLineWidth: CGFloat = 1.0
        static let dashes: [CGFloat] = [2.0, 2.0]
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        droneHalfWidth = droneImage.frame.width / 2.0

        // Init recognizers.
        let dronePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        dronePanRecognizer.delegate = self
        self.addGestureRecognizer(dronePanRecognizer)

        let touchDownRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        touchDownRecognizer.delegate = self
        // Set minimumPressDuration = 0 to use LongPressGestureRecognizer as touchDownRecognizer.
        touchDownRecognizer.minimumPressDuration = 0
        self.addGestureRecognizer(touchDownRecognizer)
    }

    override func draw(_ rect: CGRect) {
        // Draw dashed line.
        dashedLinePath = UIBezierPath()
        dashedLinePath.lineWidth = Constants.dashedLineWidth

        var start = CGPoint(x: 0.0, y: positionView.frame.origin.y)
        var end = CGPoint(x: droneImage.center.x, y: positionView.frame.origin.y)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        start = CGPoint(x: droneImage.center.x, y: positionView.frame.origin.y)
        end = CGPoint(x: droneImage.center.x, y: self.bounds.height)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)

        dashedLinePath.setLineDash(Constants.dashes, count: Constants.dashes.count, phase: 0.0)

        dashedLinePath.lineCapStyle = .butt
        dashedLinePath.close()
        ColorName.white.color.setStroke()
        dashedLinePath.stroke()
    }

    // MARK: - Internal Funcs
    /// Sets up table view cell.
    ///
    /// - Parameters:
    ///     - viewModel: geofence view model
    ///     - delegate: the action view delegate
    func setup(viewModel: GeofenceViewModel, delegate: SettingsGridActionViewDelegate?) {
        self.delegate = delegate
        userTopLimit = userImage.frame.origin.y - Constants.labelSize.height
        userLeftLimit = userImage.frame.origin.x + userImage.frame.size.width + Constants.margin

        self.viewModel = viewModel
        // Convert meters in points.
        let altitudePercent = SettingsGridView.reverseExponentialLike(value: viewModel.state.value.altitude,
                                                                      max: maxAltitude,
                                                                      min: minAltitude)
        let posY = Double(self.bounds.height) - ((altitudePercent / Values.oneHundred) * Double(self.bounds.height))
        let distancePercent = SettingsGridView.reverseExponentialLike(value: viewModel.state.value.distance,
                                                                      max: maxDistance,
                                                                      min: minDistance)
        let posX = (distancePercent / Values.oneHundred) * Double(self.bounds.width - droneHalfWidth)
        updateDroneLocation(CGPoint(x: posX, y: posY))
    }
}

// MARK: - UIGestureRecognizer Delegate
extension SettingsGridActionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension SettingsGridActionView {
    /// Handle tap gesture.
    @objc func handleTap(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            // Call updateDroneLocation and force recognizerState
            // to ended to save position on touched down.
            updateDroneLocation(recognizer.location(in: self),
                                recognizerState: .ended)
            delegate?.userIsDragging(true)
        } else {
            delegate?.userIsDragging(false)
        }
    }

    /// Handle pan gesture.
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: self)
        // Set new location to image.
        updateDroneLocation(location,
                            recognizerState: recognizer.state)
    }

    /// Update new location to drone image.
    ///
    /// - Parameters:
    ///    - newLocation: new drone location
    ///    - recognizerState: used know if this new location should be saved or checked
    func updateDroneLocation(_ newLocation: CGPoint,
                             recognizerState: UIGestureRecognizer.State = .changed) {
        // Used to know if the min Y is reached.
        var isMinAltitudeReached: Bool = false
        // Used to know if the min X is reached.
        var isMinDistanceReached: Bool = false

        // Prevent from out of limits location.
        var location: CGPoint = newLocation
        if recognizerState != UIGestureRecognizer.State.began {
            // Right.
            if location.x + droneHalfWidth > self.bounds.width {
                location = CGPoint(x: self.bounds.width - droneHalfWidth, y: location.y)
            }
            // Bottom.
            if location.y + droneHalfWidth > self.bounds.height {
                location = CGPoint(x: location.x, y: self.bounds.height - droneHalfWidth)
                isMinAltitudeReached = true
            }
            // Left.
            if location.x < droneHalfWidth {
                location = CGPoint(x: droneHalfWidth, y: location.y)
                isMinDistanceReached = true
            }
            // Top.
            if location.y < 0.0 {
                location = CGPoint(x: location.x, y: 0.0)
            }
        }

        // Used to ease computation because origin Y position is a the bottom of the view.
        let revertPosition = self.bounds.height - location.y

        // Set drone image position.
        droneImage.center = location
        // Set position view position.
        positionView.frame = CGRect(x: 0.0,
                                    y: location.y,
                                    width: location.x,
                                    height: revertPosition)

        // Convert position into meter value.
        let altitudePercent: Double = Double(revertPosition) / (Double(self.bounds.height) / Values.oneHundred)
        let distancePercent: Double = Double(location.x) / (Double(self.bounds.width - droneHalfWidth) / Values.oneHundred)
        let altitude = isMinAltitudeReached ?
            GeofencePreset.minAltitude :
            SettingsGridView.computeExponentialLike(value: altitudePercent,
                                                    max: maxAltitude,
                                                    min: minAltitude)
        let distance = isMinDistanceReached ?
            GeofencePreset.minDistance :
            SettingsGridView.computeExponentialLike(value: distancePercent,
                                                    max: maxDistance,
                                                    min: minDistance)
        heightLabel.text = UnitHelper.stringDistanceWithDouble(altitude)
        distanceLabel.text = UnitHelper.stringDistanceWithDouble(distance)

        // Position is saved only when the gesture ends.
        if recognizerState == .ended {
            // Save new postion if needed.
            viewModel?.saveGeofence(altitude: altitude, distance: distance)
        }

        // Update userImage visibility regarding drone position.
        let xDelta: CGFloat
        let yDelta: CGFloat
        if location.y > userTopLimit
            || location.x < userLeftLimit + distanceLabel.textWidth() {
            userImage.isHidden = true
            distanceLabel.textAlignment = .left
            xDelta = -Constants.margin
            yDelta = Constants.labelSize.height
        } else {
            userImage.isHidden = false
            distanceLabel.textAlignment = .right
            xDelta = Constants.labelSize.width + Constants.margin
            yDelta = 0.0
        }

        // Update label position.
        heightLabel.frame = CGRect(x: Constants.margin,
                                   y: location.y - yDelta,
                                   width: Constants.labelSize.width,
                                   height: Constants.labelSize.height)

        distanceLabel.frame = CGRect(x: positionView.frame.size.width - xDelta,
                                     y: self.bounds.height - Constants.labelSize.height,
                                     width: Constants.labelSize.width,
                                     height: Constants.labelSize.height)

        setNeedsDisplay()
    }
}

/// Settings Grid TableView Cell.
final class SettingsGridTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var gridViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gridView: SettingsGridView!
    @IBOutlet private weak var actionView: SettingsGridActionView!

    // MARK: - Private Properties
    /// View used to apply disable style (grayed) on the cell.
    private let grayedView = UIView()
    private weak var delegate: SettingsGridActionViewDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        grayedView.backgroundColor = ColorName.black40.color
        actionView.addWithConstraints(subview: grayedView)

        enableView(isEnabled: false)
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - viewModel: Geofence view model
    ///     - maxGridHeight: The max grid height
    func configureCell(viewModel: GeofenceViewModel,
                       maxGridHeight: CGFloat,
                       delegate: SettingsGridActionViewDelegate?) {
        gridViewHeightConstraint.constant = maxGridHeight
        enableView(isEnabled: viewModel.state.value.isGeofenceActivated)
        actionView.setup(viewModel: viewModel, delegate: self)
        self.delegate = delegate
    }
}

// MARK: - Private Funcs
private extension SettingsGridTableViewCell {
    /// Enable or not the view.
    ///
    /// - Parameters:
    ///     - isEnabled: Is enable
    func enableView(isEnabled: Bool) {
        grayedView.isHidden = isEnabled
        self.isUserInteractionEnabled = isEnabled
    }
}

// MARK: - Settings Grid Action View Delegate
extension SettingsGridTableViewCell: SettingsGridActionViewDelegate {
    func userIsDragging(_ isDragging: Bool) {
        delegate?.userIsDragging(isDragging)
    }
}
