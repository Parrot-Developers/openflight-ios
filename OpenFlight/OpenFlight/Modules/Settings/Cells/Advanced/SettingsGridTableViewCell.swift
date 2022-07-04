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

/// Manages drone gesture and display.
class SettingsGridActionView: UIView {
    // MARK: - Outlets
    @IBOutlet private weak var positionView: UIView!
    @IBOutlet private weak var userImage: UIImageView!
    @IBOutlet private weak var pointImage: UIImageView!
    @IBOutlet private weak var heightLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var yAxisView: UIView!

    // MARK: - Private Properties
    private var dashedLinePath = UIBezierPath()
    private var droneHalfWidth: CGFloat = 0.0
    private var cancellables = Set<AnyCancellable>()
    private var viewModel = GeofenceViewModel(currentDroneHolder: Services.hub.currentDroneHolder)

    var isEnabled: Bool = false {
        didSet {
            let textColor = isEnabled ? ColorName.highlightColor.color : ColorName.disabledHighlightColor.color
            let imageAlpha: CGFloat = isEnabled ? 1.0 : Style.disabledAlpha
            heightLabel.textColor = textColor
            distanceLabel.textColor = textColor
            positionView.alpha = isEnabled ? Style.disabledAlpha : Style.disabledAlpha / 2.0
            yAxisView.alpha = isEnabled ? 1.0 : Style.disabledAlpha
            pointImage.alpha = imageAlpha
            userImage.alpha = imageAlpha
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let margin: CGFloat = 8.0
        static let labelSize: CGSize = CGSize(width: 100.0, height: 25.0)
        static let dashedLineWidth: CGFloat = 1.0
        static let dashes: [CGFloat] = [2.0, 2.0]
        static let pointImageAreaRatio: CGFloat = 2.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        listenViewModel()
    }

    override func draw(_ rect: CGRect) {
        // Draw dashed line.
        dashedLinePath = UIBezierPath()
        dashedLinePath.lineWidth = Constants.dashedLineWidth

        var start = CGPoint(x: 0.0, y: positionView.frame.origin.y)
        var end = CGPoint(x: pointImage.center.x - pointImage.frame.width / 2.0, y: positionView.frame.origin.y)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        start = CGPoint(x: pointImage.center.x, y: positionView.frame.origin.y + pointImage.frame.height / 2.0)
        end = CGPoint(x: pointImage.center.x, y: bounds.height)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)

        dashedLinePath.setLineDash(Constants.dashes, count: Constants.dashes.count, phase: 0.0)

        dashedLinePath.lineCapStyle = .butt
        dashedLinePath.close()
        isEnabled ? ColorName.defaultTextColor.color.setStroke() : ColorName.disabledTextColor.color.setStroke()
        dashedLinePath.stroke()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let droneImageArea = CGRect(center: pointImage.center,
                                    width: Constants.pointImageAreaRatio * pointImage.frame.width,
                                    height: Constants.pointImageAreaRatio * pointImage.frame.height)

        guard isEnabled, droneImageArea.contains(point) else {
            return superview
        }

        return self
    }

    // MARK: - Internal Funcs
    /// Updates view.
    func updateView(altitude: Double,
                    maxAltitude: Double,
                    minAltitude: Double,
                    distance: Double,
                    maxDistance: Double,
                    minDistance: Double,
                    isGeofenceActivated: Bool) {
        // Convert meters in points.
        let altitudePercent = SettingsGridView.reverseExponentialLike(value: altitude,
                                                                      max: maxAltitude,
                                                                      min: minAltitude)
        let posY = Double(bounds.height) - ((altitudePercent / Values.oneHundred) * Double(bounds.height))

        let distancePercent = SettingsGridView.reverseExponentialLike(value: distance,
                                                                      max: maxDistance,
                                                                      min: minDistance)
        let posX = (distancePercent / Values.oneHundred) * Double(bounds.width - droneHalfWidth)
        enableView(isEnabled: isGeofenceActivated)
        updateDroneLocation(CGPoint(x: posX, y: posY))
    }
}

// MARK: - Private Funcs
private extension SettingsGridActionView {
    /// Inits the view.
    func initView() {
        droneHalfWidth = pointImage.frame.width / 2.0

        // Init recognizers.
        let dronePanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(dronePanRecognizer)
    }

    /// Listens the view model.
    func listenViewModel() {
        viewModel.$altitude.removeDuplicates()
            .combineLatest(viewModel.$isGeofenceActivated.removeDuplicates(),
                           viewModel.$distance.removeDuplicates(),
                           viewModel.$minDistance.removeDuplicates())
            .combineLatest(viewModel.$maxDistance.removeDuplicates(),
                           viewModel.$minAltitude.removeDuplicates(),
                           viewModel.$maxAltitude.removeDuplicates())
        // We use receive(on: ) to ensure that the cell has his correct size before updating the view
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (arg0, maxDistance, minAltitude, maxAltitude) in
                let (altitude, isGeofenceActivated, distance, minDistance) = arg0
                guard let self = self else { return }
                self.updateView(altitude: altitude,
                                maxAltitude: maxAltitude,
                                minAltitude: minAltitude,
                                distance: distance,
                                maxDistance: maxDistance,
                                minDistance: minDistance,
                                isGeofenceActivated: isGeofenceActivated)
            }
            .store(in: &cancellables)

        showViews()
    }

    /// Handle pan gesture.
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        var shouldSaveValue: Bool = false
        var location = recognizer.location(in: self)
        if recognizer.state != UIGestureRecognizer.State.began {
            // Right.
            if location.x + droneHalfWidth > bounds.width {
                location = CGPoint(x: bounds.width - droneHalfWidth, y: location.y)
            }
            // Bottom.
            if location.y + droneHalfWidth > bounds.height {
                location = CGPoint(x: location.x, y: bounds.height - droneHalfWidth)
            }
            // Left.
            if location.x < droneHalfWidth {
                location = CGPoint(x: droneHalfWidth, y: location.y)
            }
            // Top.
            if location.y < 0.0 {
                location = CGPoint(x: location.x, y: 0.0)
            }
        }

        if recognizer.state == UIGestureRecognizer.State.ended {
            // Position is saved only when the gesture ends.
            shouldSaveValue = true
        }

        // Set new location to image.
        updateDroneLocation(location,
                            shouldSaveValue: shouldSaveValue)
    }

    /// Enable or not the view.
    ///
    /// - Parameters:
    ///     - isEnabled: Is enable
    func enableView(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    /// Update new location to drone image.
    ///
    /// - Parameters:
    ///    - location: new drone location
    ///    - shouldSaveValue: used know if this new location should be saved
    func updateDroneLocation(_ location: CGPoint,
                             shouldSaveValue: Bool = false) {

        // Used to ease computation because origin Y position is a the bottom of the view.
        let revertPosition = bounds.height - location.y

        // Set drone image position.
        pointImage.center = location
        // Set position view position.
        positionView.frame = CGRect(x: 0.0,
                                    y: location.y,
                                    width: location.x,
                                    height: revertPosition)

        // Convert position into meter value.
        let altitudePercent: Double = Double(revertPosition) / (Double(bounds.height) / Values.oneHundred)
        let distancePercent: Double = Double(location.x) / (Double(bounds.width - droneHalfWidth) / Values.oneHundred)
        let altitude = SettingsGridView.computeExponentialLike(value: altitudePercent,
                                                               max: viewModel.maxAltitude,
                                                               min: viewModel.minAltitude)
        let distance = SettingsGridView.computeExponentialLike(value: distancePercent,
                                                               max: viewModel.maxDistance,
                                                               min: viewModel.minDistance)
        heightLabel.text = UnitHelper.stringDistanceWithDouble(altitude)
        distanceLabel.text = UnitHelper.stringDistanceWithDouble(distance)

        // Update userImage visibility regarding drone position.
        var xDelta: CGFloat
        var xDeltaHeightLabel: CGFloat
        var yDelta: CGFloat
        let halfDroneImageSize = CGSize(width: pointImage.frame.width / 2.0,
                                        height: pointImage.frame.height / 2.0)
        // Computes distance label position.
        var checkYDroneImage = false
        var distanceAlignment: NSTextAlignment = .left
        if positionView.frame.width > userImage.frame.origin.x +
            userImage.frame.width +
            distanceLabel.textWidth() +
            2 * Constants.margin {
            xDelta = distanceLabel.textWidth() + Constants.margin
            xDeltaHeightLabel = Constants.margin
        } else {
            distanceAlignment = .right
            xDelta = -halfDroneImageSize.width
            xDeltaHeightLabel = positionView.frame.size.width - xDelta
        }

        // Computes height label position.
        if positionView.frame.height > userImage.frame.height +
            heightLabel.frame.height +
            2 * Constants.margin {
            yDelta = 0.0
        } else {
            yDelta = Constants.labelSize.height
            checkYDroneImage = true
        }

        if checkYDroneImage && positionView.frame.height >= halfDroneImageSize.height {
            xDelta = -halfDroneImageSize.width
        }

        // Updates labels position
        distanceLabel.frame = CGRect(x: positionView.frame.size.width - xDelta,
                                     y: bounds.height - distanceLabel.frame.height,
                                     width: distanceLabel.textWidth(),
                                     height: distanceLabel.frame.height)
        distanceLabel.textAlignment = distanceAlignment

        heightLabel.frame = CGRect(x: xDeltaHeightLabel,
                                   y: location.y - yDelta,
                                   width: Constants.labelSize.width,
                                   height: Constants.labelSize.height)
        setNeedsDisplay()

        if shouldSaveValue {
            // Save new geofence if needed.
            viewModel.saveGeofence(altitude: altitude, distance: distance)
        }
    }

    /// Show all views
    func showViews() {
        positionView.isHidden = false
        distanceLabel.isHidden = false
        heightLabel.isHidden = false
        pointImage.isHidden = false
    }
}

/// Settings Grid TableView Cell.
final class SettingsGridTableViewCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var gridViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gridView: SettingsGridView!
    @IBOutlet private weak var actionView: SettingsGridActionView!

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - maxGridHeight: The max grid height
    func configureCell(maxGridHeight: CGFloat) {
        gridView.isYAxisHidden = true
        gridViewHeightConstraint.constant = maxGridHeight
    }
}
