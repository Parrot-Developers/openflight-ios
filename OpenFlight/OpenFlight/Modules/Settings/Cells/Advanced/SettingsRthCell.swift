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

/// Manages return to home gesture and display.
final class SettingsRthActionView: UIView {
    // MARK: - Outlets
    @IBOutlet private weak var positionView: UIView!
    @IBOutlet private weak var homeImage: UIImageView!
    @IBOutlet private weak var droneImage: UIImageView!
    @IBOutlet private weak var pointImage: UIImageView!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var lineView: UIView!

    // MARK: - Private Enums
    private enum Constants {
        static let homeHeightRatio: CGFloat = 1.3
        static let pointImageAreaRatio: CGFloat = 4.0
        static let margin: CGFloat = 8.0
        static let arrowLength: CGFloat = 5.0
        static let dashedLineWidth: CGFloat = 1.0
        static let dashes: [CGFloat] = [2.0, 2.0]
        static let lineWidth: CGFloat = 2.0
        static let labelSize: CGSize = CGSize(width: 80.0, height: 25.0)
    }

    // MARK: - Private Properties
    private var dashedLinePath = UIBezierPath()
    private var pointerHalfWidth: CGFloat = 0.0
    private var minHeight: CGFloat = 0.0
    private var viewModel = SettingsRthActionViewModel(currentDroneHolder: Services.hub.currentDroneHolder,
                                                       rthSettingsMonitor: Services.hub.rthSettingsMonitor)
    private var initialCenter: CGPoint = .zero
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        initView()
        listenViewModel()
    }

    override func draw(_ rect: CGRect) {
        let homeImageTop = homeImage.frame.origin.y - Constants.margin / 2.0
        // Draw dashed line.
        dashedLinePath = UIBezierPath()
        dashedLinePath.lineWidth = Constants.dashedLineWidth

        var start = CGPoint(x: homeImage.center.x, y: homeImageTop)
        var end = CGPoint(x: homeImage.center.x, y: positionView.frame.origin.y)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        start = CGPoint(x: homeImage.center.x, y: positionView.frame.origin.y)
        end = CGPoint(x: droneImage.center.x, y: positionView.frame.origin.y)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        start = CGPoint(x: droneImage.center.x, y: positionView.frame.origin.y)
        end = CGPoint(x: droneImage.center.x, y: droneImage.frame.origin.y - Constants.margin / 2)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)

        dashedLinePath.setLineDash(Constants.dashes, count: Constants.dashes.count, phase: 0.0)

        dashedLinePath.lineCapStyle = .butt
        dashedLinePath.close()
        ColorName.defaultTextColor.color.setStroke()
        dashedLinePath.stroke()

        // Draw arrow.
        dashedLinePath = UIBezierPath()
        dashedLinePath.lineWidth = Constants.dashedLineWidth
        start = CGPoint(x: homeImage.center.x - Constants.arrowLength,
                        y: homeImageTop - Constants.arrowLength)
        end = CGPoint(x: homeImage.center.x, y: homeImageTop)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        start = CGPoint(x: homeImage.center.x, y: homeImageTop)
        end = CGPoint(x: homeImage.center.x + Constants.arrowLength,
                      y: homeImageTop - Constants.arrowLength)
        dashedLinePath.move(to: start)
        dashedLinePath.addLine(to: end)
        dashedLinePath.close()
        ColorName.defaultTextColor.color.setStroke()
        dashedLinePath.stroke()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let pointImageArea = CGRect(center: pointImage.center,
                                    width: droneImage.center.x - homeImage.center.x,
                                    height: Constants.pointImageAreaRatio * pointImage.frame.height)

        guard pointImageArea.contains(point) else {
            return superview
        }

        return self
    }

    // MARK: - Internal Funcs
    /// Updates view.
    func updateView(minAltitude: Double,
                    altitude: Double,
                    maxAltitude: Double) {
        // Convert meters in points.
        let altitudePercent = SettingsGridView.reverseExponentialLike(value: altitude,
                                                                      max: maxAltitude,
                                                                      min: minAltitude)
        let deltaHeight = Double(bounds.height - minHeight)
        let posY = deltaHeight - ((altitudePercent / Values.oneHundred) * deltaHeight)
        // Update display.
        updatePointerLocation(CGPoint(x: 0.0, y: posY))
    }
}

// MARK: - Private Funcs
private extension SettingsRthActionView {
    /// Inits the view.
    func initView() {
        pointerHalfWidth = pointImage.frame.width / 2.0
        minHeight = homeImage.frame.height * Constants.homeHeightRatio

        // Init recognizers.
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        addGestureRecognizer(panRecognizer)
    }

    /// Listens the view model.
    func listenViewModel() {
        viewModel.$maxAltitude.removeDuplicates()
            .combineLatest(viewModel.$altitude.removeDuplicates(),
                           viewModel.$minAltitude.removeDuplicates())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (maxAltitude, altitude, minAltitude) in
                guard let self = self else { return }
                self.updateView(minAltitude: minAltitude,
                                altitude: altitude,
                                maxAltitude: maxAltitude)
            }
            .store(in: &cancellables)

        showViews()
    }

    /// Handle pan gesture.
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        var shouldSaveValue: Bool = false
        var location = recognizer.location(in: self)
        let translation = recognizer.translation(in: self)
        switch recognizer.state {
        case .began:
            initialCenter = pointImage.center
        case .ended:
            // Position is saved only when the gesture ends.
            shouldSaveValue = true
            fallthrough
        case .changed:
            location = CGPoint(x: location.x, y: initialCenter.y + translation.y)
            // Prevent from out of limits location.
            // Bottom.
            if location.y > bounds.height - minHeight {
                location = CGPoint(x: location.x, y: bounds.height - minHeight)
            }
            // Top.
            if location.y < 0.0 {
                location = CGPoint(x: location.x, y: 0.0)
            }
            // Set new location to image.
            updatePointerLocation(location,
                                  shouldSaveValue: shouldSaveValue)
        default:
            break
        }
    }

    /// Update new location to drone image.
    ///
    /// - Parameters:
    ///    - location: new drone location
    ///    - shouldSaveValue: used know if this new location should be saved
    func updatePointerLocation(_ location: CGPoint,
                               shouldSaveValue: Bool = false) {
        let revertPosition = bounds.height - location.y
        let gridXCenter = (droneImage.center.x + homeImage.center.x) / 2

        // Set position view position.
        positionView.frame = CGRect(x: homeImage.center.x,
                                    y: location.y,
                                    width: droneImage.center.x - homeImage.center.x,
                                    height: revertPosition)

        lineView.frame = CGRect(x: gridXCenter - Constants.lineWidth / 2,
                                y: location.y + pointerHalfWidth,
                                width: Constants.lineWidth,
                                height: revertPosition - pointerHalfWidth)

        // Set Label position and value.
        let deltaHeight = Double(bounds.height - minHeight)
        let altitudePercent: Double = Double(revertPosition - minHeight) / (deltaHeight / Values.oneHundred)
        let altitude = SettingsGridView.computeExponentialLike(value: altitudePercent,
                                                               max: viewModel.maxAltitude,
                                                               min: viewModel.minAltitude)
        infoLabel.text = UnitHelper.stringDistanceWithDouble(altitude)
        infoLabel.frame = CGRect(x: gridXCenter + Constants.margin,
                                 y: (location.y + (revertPosition / 2)) - Constants.labelSize.height / 2,
                                 width: Constants.labelSize.width,
                                 height: Constants.labelSize.height)

        // Set pointer image position.
        pointImage.center = CGPoint(x: gridXCenter, y: location.y)

        setNeedsDisplay()

        // Save new altitude if needed.
        if shouldSaveValue {
            let convertedAltitude = UnitHelper.roundedDistanceWithDouble(altitude)
            viewModel.saveRth(altitude: convertedAltitude)
        }
    }

    /// Show all views
    func showViews() {
        positionView.isHidden = false
        lineView.isHidden = false
        infoLabel.isHidden = false
        pointImage.isHidden = false
    }
}

/// Settings return to home cell.
final class SettingsRthCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var gridViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var gridView: SettingsGridView!
    @IBOutlet private weak var actionView: SettingsRthActionView!

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        gridView.isYAxisHidden = true
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - maxGridHeight: Maxium height for grid
    func configureCell(maxGridHeight: CGFloat) {
        gridViewHeightConstraint.constant = maxGridHeight
    }
}
