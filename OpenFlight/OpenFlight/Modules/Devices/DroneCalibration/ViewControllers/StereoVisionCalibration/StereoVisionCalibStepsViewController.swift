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
import GroundSdk

/// View Controller used to display frame necessary to Stereo Vision calibration screen.
final class StereoVisionCalibStepsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var renderView: UIView!
    @IBOutlet private weak var loaderImageView: UIImageView!
    @IBOutlet private weak var handImageView: UIImageView!
    @IBOutlet private weak var progressContainerView: UIView!

    // MARK: - Private Properties
    private weak var coordinator: DroneCalibrationCoordinator?
    private var viewModel = StereoVisionSensorCalibrationViewModel()
    private var isRequired: Bool = false
    private var currentPositionLayers: [CAShapeLayer] = []
    private var requiredPositionLayers: [CAShapeLayer] = []
    private var circleLayer = CAShapeLayer()
    private var progressBar = DottedProgressBar()
    private var isCalibrated: Bool = false

    // MARK: - Internal Enums
    /// Enum which gives x and y coordinates for current position rectangles.
    enum RectangleCorner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight

        /// Gives x and y coordinates for point in corner.
        ///
        /// - Parameters:
        ///    - position: Required or current frame of board.
        func point(for position: StereoVisionFrame) -> CGPoint {
            var xCoordinate: Double = 0.0
            var yCoordinate: Double = 0.0
            switch self {
            case .topLeft:
                xCoordinate = position.getLeftTopVertex().getX()
                yCoordinate = position.getLeftTopVertex().getY()
            case .topRight:
                xCoordinate = position.getRightTopVertex().getX()
                yCoordinate = position.getRightTopVertex().getY()
            case .bottomLeft:
                xCoordinate = position.getLeftBottomVertex().getX()
                yCoordinate = position.getLeftBottomVertex().getY()
            case .bottomRight:
                xCoordinate = position.getRightBottomVertex().getX()
                yCoordinate = position.getRightBottomVertex().getY()
            }

            return CGPoint(x: xCoordinate, y: yCoordinate)
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let currentOrientation: String = "orientation"
        static let rotationAngle = -CGFloat.pi
        static let greyCircleRadius: CGFloat = 27.0
        static let greenBallAlpha: CGFloat = 0.7
        static let greenBallRadius: CGFloat = 23.0
        static let boardWhiteBorder: CGFloat = 2.0
        static let ballRatioAngle: Double = 90.0
        static let ballDivider: Double = 4.0
        static let ballCoeff: Double = 1.0
        static let loaderAnimationDuration: Double = 40.0
        static let greenCornersBorder: CGFloat = 5.0
        static let loaderRadius: Int = 45
        static let dottedProgressBarDotRadius: CGFloat = 4.0
        static let dottedProgressBarWidth: CGFloat = 20.0
        static let dottedProgressBarHeight: CGFloat = UIScreen.main.bounds.height - 10.0
        static let dottedProgressBarY: CGFloat = 10.0
        static let requiredRectangleCote: CGFloat = 29.0
        static let requiredPlanBorder: CGFloat = 1.0
        static let requiredRectangleBorder: CGFloat = 1.8
        static let currentRectangleCote: CGFloat = 24.0
        static let requiredCircleRadius: CGFloat = 14.0
        static let currentCircleRadius: CGFloat = 12.0
    }

    /// Enum which stores messages to log.
    private enum EventLoggerConstants {
        static let screenMessage: String = "SensorCalibration"
    }

    // MARK: - Setup
    /// Instantiate View controller.
    ///
    /// - Parameters:
    ///     - isRequired: tell if the calibration is required
    ///     - coordinator: navigation coordinator
    /// - Returns: Steps of stereo vision calibration view controller
    static func instantiate(isRequired: Bool = false, coordinator: DroneCalibrationCoordinator) -> StereoVisionCalibStepsViewController {
        let viewController = StoryboardScene.StereoVisionCalibration.stereoVisionCalibrationStepsViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.isRequired = isRequired

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initUI()
        self.setupViewModels()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        logScreen(logMessage: EventLoggerConstants.screenMessage)
        self.viewModel.startCalibration()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.viewModel.cancelCalibration()
        cleanLayers()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension StereoVisionCalibStepsViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        self.coordinator?.back()
    }
}

// MARK: - Private Funcs
private extension StereoVisionCalibStepsViewController {
    /// Removes created layers for previous calibration.
    func cleanLayers() {
        for layer in self.currentPositionLayers { layer.removeFromSuperlayer() }
        for layer in self.requiredPositionLayers { layer.removeFromSuperlayer() }
    }

    /// Update background color for both viewController view and renderView.
    ///
    /// - Parameters:
    ///    - color: new color to set.
    func updateBackgroundColor(_ color: Color) {
        self.view.backgroundColor = color
        self.renderView.backgroundColor = color
    }

    /// Sets up view for dots progress bar.
    ///
    /// - Parameters:
    ///    - numberOfSteps: Number of steps to calibrate stereo vision sensor.
    func addDottedProgressBar (numberOfSteps: Int) {
        progressBar.progressAppearance = DottedProgressBar.DottedProgressAppearance(
            dotRadius: Constants.dottedProgressBarDotRadius,
            dotsColor: ColorName.white50.color,
            dotsProgressColor: ColorName.greenSpring.color,
            backColor: UIColor.clear
        )
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.transform = CGAffineTransform(rotationAngle: Constants.rotationAngle)
        progressBar.frame = CGRect(x: 0.0,
                                   y: Constants.dottedProgressBarY,
                                   width: Constants.dottedProgressBarWidth,
                                   height: Constants.dottedProgressBarHeight)
        progressContainerView.addSubview(progressBar)
        progressBar.setNumberOfDots(numberOfSteps)
    }

    /// Initializes all the UI for the view controller.
    func initUI() {
        self.titleLabel.text = L10n.sensorCalibrationTutorialTitle
        self.titleLabel.textColor = ColorName.greenSpring.color
        self.updateBackgroundColor(ColorName.greenPea.color)
        self.loaderImageView.isHidden = true
        self.handImageView.isHidden = true
    }

    /// Sets up view models associated with the view.
    func setupViewModels() {
        self.viewModel.state.valueChanged = { [weak self] state in
            if let calibrationStepsCount = state.calibrationStepsCount {
                self?.addDottedProgressBar(numberOfSteps: calibrationStepsCount)
            }
            if let calibrationProcessState = state.calibrationProcessState {
                if let indication = state.calibrationProcessState?.indication {
                    self?.updateBackgroundColor(ColorName.greenPea.color)
                    self?.titleLabel.textColor = ColorName.greenSpring.color
                    self?.setIndicationTitle(indication: indication)
                }
                if let currentStep = state.calibrationProcessState?.currentStep {
                    self?.progressBar.setProgress(currentStep + 1)
                }
                self?.showStereoVisionCanvasUI(calibrationProcessState: calibrationProcessState)
            }
        }
    }

    /// Change title switch stereo vision indication.
    ///
    /// - Parameters:
    ///    - indication: indication of the stereo vision sensor.
    func setIndicationTitle(indication: StereoVisionIndication) {
        self.titleLabel.text = indication.title

        if indication == .stop {
            self.titleLabel.textColor = ColorName.greyShark.color
            self.updateBackgroundColor(ColorName.greenHaze.color)
        }
    }

    /// Shows frame taking board to calibrate Stereo Vision.
    ///
    /// - Parameters:
    ///    - calibrationProcessState: state of the stereo vision sensor.
    func showStereoVisionCanvasUI(calibrationProcessState: StereoVisionCalibrationProcessState) {
        if let requiredPosition = calibrationProcessState.requiredPosition {
            // Clean previous position.
            for layer in self.requiredPositionLayers {
                layer.removeFromSuperlayer()
            }
            for layer in self.currentPositionLayers {
                layer.removeFromSuperlayer()
            }
            self.currentPositionLayers.removeAll()
            self.requiredPositionLayers.removeAll()

            // Hide handloader from previous position.
            self.loaderImageView.stopRotate()
            self.loaderImageView.isHidden = true
            self.handImageView.isHidden = true

            // Add required frame.
            let requiredPositionLayer = addRequiredPositionPlan(indication: calibrationProcessState.indication,
                                                                requiredPosition: requiredPosition)
            let leftTopLayer = addRequiredCornerRectangle(for: .topLeft,
                                                          requiredPosition: requiredPosition)
            let rightTopLayer = addRequiredCornerCircle(for: .topRight,
                                                        requiredPosition: requiredPosition)
            let rightBottomLayer = addRequiredCornerRectangle(for: .bottomRight,
                                                              requiredPosition: requiredPosition)
            let leftBottomLayer = addRequiredCornerCircle(for: .bottomLeft,
                                                          requiredPosition: requiredPosition)

            self.requiredPositionLayers.append(contentsOf: [requiredPositionLayer,
                                                            leftTopLayer,
                                                            rightTopLayer,
                                                            rightBottomLayer,
                                                            leftBottomLayer])
        }

        if self.shouldShow(from: calibrationProcessState.indication),
           let currentPosition = calibrationProcessState.currentPosition {
            for layer in self.currentPositionLayers {
                layer.removeFromSuperlayer()
                self.currentPositionLayers.removeAll()
            }
            let currentPositionLayer = addCurrentPlan(currentPosition: currentPosition)
            let currentTopLeftLayer = addCurrentCornerRectangle(for: .topLeft,
                                                                currentPosition: currentPosition)
            let currentBottomLeftLayer = addCurrentCornerCircle(for: .bottomLeft,
                                                                currentPosition: currentPosition)
            let currentTopRightLayer = addCurrentCornerCircle(for: .topRight,
                                                              currentPosition: currentPosition)
            let currentBottomRightLayer = addCurrentCornerRectangle(for: .bottomRight,
                                                                    currentPosition: currentPosition)
            self.currentPositionLayers.append(contentsOf: [currentPositionLayer,
                                                           currentTopLeftLayer,
                                                           currentBottomLeftLayer,
                                                           currentTopRightLayer,
                                                           currentBottomRightLayer])
        }

        if let requiredPosition = calibrationProcessState.requiredPosition,
           let requiredRotation = calibrationProcessState.requiredRotation {
            let requiredBallPath = UIBezierPath(
                arcCenter: (self.ballCorrected( rotation: requiredRotation,
                                                frame: requiredPosition)),
                radius: CGFloat(Constants.greyCircleRadius),
                startAngle: CGFloat.zero,
                endAngle: CGFloat(Double.pi * 2),
                clockwise: true)
            let requiredBallLayer = CAShapeLayer()
            requiredBallLayer.path = requiredBallPath.cgPath
            requiredBallLayer.strokeColor = UIColor.lightGray.cgColor
            requiredBallLayer.lineWidth = Constants.requiredRectangleBorder
            requiredBallLayer.fillColor = UIColor.clear.cgColor
            self.renderView.layer.addSublayer(requiredBallLayer)
            self.requiredPositionLayers.append(requiredBallLayer)
        }

        if self.shouldShow(from: calibrationProcessState.indication),
           let requiredPosition = calibrationProcessState.requiredPosition,
           let currentRotation = calibrationProcessState.currentRotation {
            let currentBallPath = UIBezierPath(
                arcCenter: (self.ballCorrected(rotation: currentRotation,
                                               frame: requiredPosition)),
                radius: CGFloat(Constants.greenBallRadius),
                startAngle: CGFloat.zero,
                endAngle: CGFloat(Double.pi * 2),
                clockwise: true)
            let currentBallLayer = CAShapeLayer()
            currentBallLayer.path = currentBallPath.cgPath
            currentBallLayer.fillColor = ColorName.greenSpring.color.withAlphaComponent(Constants.greenBallAlpha).cgColor
            self.renderView.layer.addSublayer(currentBallLayer)
            self.currentPositionLayers.append(currentBallLayer)
        }

        if calibrationProcessState.isComputing {
            handImageView.isHidden = true
            loaderImageView.isHidden = true
            for layer in self.currentPositionLayers { layer.removeFromSuperlayer() }
            for layer in self.requiredPositionLayers { layer.removeFromSuperlayer() }
            self.titleLabel.text = L10n.gimbalCalibrationCalibrating
            configureCircleLayer()
            startCircleAnimation(calibrationState: calibrationProcessState)
        }

        if !calibrationProcessState.isComputing
            && calibrationProcessState.result != .none {
            startCalibrationResult(calibrationState: calibrationProcessState)
        }
    }

    /// Shows Stereo Vision calibration result.
    ///
    /// - Parameters:
    ///    - calibrationState: state of the stereo vision sensor.
    func startCalibrationResult(calibrationState: StereoVisionCalibrationProcessState) {
        switch calibrationState.result {
        case .success:
            self.isCalibrated = true
        case .failed:
            self.isCalibrated = false
        default:
            return
        }

        self.coordinator?.startStereoVisionCalibrationResult(isCalibrated: self.isCalibrated)
    }

    /// Add frame in which adapt board.
    ///
    /// - Parameters:
    ///     - indication: current indication
    ///     - requiredPosition: Required Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addRequiredPositionPlan(indication: StereoVisionIndication, requiredPosition: StereoVisionFrame) -> CAShapeLayer {
        let requiredPositionLayer = CAShapeLayer()
        self.renderView.layer.addSublayer(requiredPositionLayer)
        requiredPositionLayer.lineJoin = CAShapeLayerLineJoin.miter
        requiredPositionLayer.fillColor = ColorName.black60.color.cgColor
        requiredPositionLayer.strokeColor = ColorName.greenSpring.color.cgColor
        requiredPositionLayer.lineWidth = Constants.requiredPlanBorder
        let path = UIBezierPath()
        path.move(to: (self.pointCorrected(
                        point: CGPoint(x: requiredPosition.getLeftTopVertex().getX(),
                                       y: requiredPosition.getLeftTopVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: requiredPosition.getRightTopVertex().getX(),
                                           y: requiredPosition.getRightTopVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: requiredPosition.getRightBottomVertex().getX(),
                                           y: requiredPosition.getRightBottomVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: requiredPosition.getLeftBottomVertex().getX(),
                                           y: requiredPosition.getLeftBottomVertex().getY()))))
        path.close()
        requiredPositionLayer.path = path.cgPath
        if indication == .stop {
            requiredPositionLayer.fillColor = ColorName.greySilver.color.cgColor
            requiredPositionLayer.strokeColor = UIColor.black.cgColor
            requiredPositionLayer.lineWidth = Style.largeBorderWidth
            handImageView.isHidden = false
            loaderImageView.isHidden = false
            loaderImageView.startRotate()
        }

        return requiredPositionLayer
    }

    /// Create required layer using required position.
    ///
    /// - Parameters:
    ///     - layer: Layer to add to the required plan
    ///     - path: Path of required layer using UIBezierPath
    func createRequiredLayer(layer: CAShapeLayer, path: CGPath) {
        layer.path = path
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = ColorName.greenSpring.color.cgColor
        layer.lineWidth = Constants.requiredRectangleBorder
        self.renderView.layer.addSublayer(layer)
    }

    /// Add required rectangle.
    ///
    /// - Parameters:
    ///     - corner: Corner in wich add rectangle
    ///     - requiredPosition: required Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addRequiredCornerRectangle(for corner: RectangleCorner, requiredPosition: StereoVisionFrame) -> CAShapeLayer {
        let requiredPath = UIBezierPath(rect: CGRect(center: (self.pointCorrected(
                                                                point: corner.point(for: requiredPosition))),
                                                     width: Constants.requiredRectangleCote,
                                                     height: Constants.requiredRectangleCote))
        let requiredLayer = CAShapeLayer()
        createRequiredLayer(layer: requiredLayer,
                            path: requiredPath.cgPath)

        return requiredLayer
    }

    /// Add required circle.
    ///
    /// - Parameters:
    ///     - corner: Corner in which add circle
    ///     - requiredPosition: Required Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addRequiredCornerCircle(for corner: RectangleCorner, requiredPosition: StereoVisionFrame) -> CAShapeLayer {
        let requiredPoint = self.pointCorrected(point: corner.point(for: requiredPosition))
        let requiredPath = UIBezierPath(arcCenter: requiredPoint,
                                        radius: CGFloat(Constants.requiredCircleRadius),
                                        startAngle: CGFloat.zero,
                                        endAngle: CGFloat(Double.pi * 2),
                                        clockwise: true)
        let requiredLayer = CAShapeLayer()
        createRequiredLayer(layer: requiredLayer,
                            path: requiredPath.cgPath)

        return requiredLayer
    }

    /// Show or not the board in current posistion
    ///
    /// - Parameters:
    ///     - indication: Indication to the board position
    /// - Returns: a boolean indicating if we need to show the current ball.
    func shouldShow(from indication: StereoVisionIndication) -> Bool {
        var ballReturned = true
        switch indication {
        case .checkBoardAndCameras, .placeWithinSight, .none:
            ballReturned = false
        default:
            ballReturned = true
        }
        return ballReturned
    }

    /// Add current board frame.
    ///
    /// - Parameters:
    ///     - currentPosition: current Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addCurrentPlan(currentPosition: StereoVisionFrame) -> CAShapeLayer {
        let currentPositionLayer = CAShapeLayer()
        self.renderView.layer.addSublayer(currentPositionLayer)
        currentPositionLayer.lineWidth = CGFloat(Constants.boardWhiteBorder)
        currentPositionLayer.strokeColor = ColorName.white.color.cgColor
        currentPositionLayer.lineJoin = CAShapeLayerLineJoin.miter
        currentPositionLayer.fillColor = ColorName.white50.color.cgColor
        let path = UIBezierPath()
        path.move(to: (self.pointCorrected(
                        point: CGPoint(x: currentPosition.getLeftTopVertex().getX(),
                                       y: currentPosition.getLeftTopVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: currentPosition.getRightTopVertex().getX(),
                                           y: currentPosition.getRightTopVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: currentPosition.getRightBottomVertex().getX(),
                                           y: currentPosition.getRightBottomVertex().getY()))))
        path.addLine(to: (self.pointCorrected(
                            point: CGPoint(x: currentPosition.getLeftBottomVertex().getX(),
                                           y: currentPosition.getLeftBottomVertex().getY()))))
        path.close()
        currentPositionLayer.path = path.cgPath

        return currentPositionLayer
    }

    /// Create current layer using current position.
    ///
    /// - Parameters:
    ///     - layer: Layer to add to the current plan
    ///     - path: Path of current layer using uiberzierthpath
    ///     - currentPosition: current Frame of board
    func createCurrentLayer(layer: CAShapeLayer, path: CGPath) {
        layer.path = path
        layer.fillColor = ColorName.greenSpring.color.cgColor
        self.renderView.layer.addSublayer(layer)
    }

    /// Add current rectangle.
    ///
    /// - Parameters:
    ///     - corner: Corner in wich add rectangle
    ///     - currentPosition: current Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addCurrentCornerRectangle(for corner: RectangleCorner, currentPosition: StereoVisionFrame) -> CAShapeLayer {
        let currentPath = UIBezierPath(rect: CGRect(center: (self.pointCorrected(
                                                                point: corner.point(for: currentPosition))),
                                                    width: Constants.currentRectangleCote,
                                                    height: Constants.currentRectangleCote))
        let currentLayer = CAShapeLayer()
        createCurrentLayer(layer: currentLayer,
                           path: currentPath.cgPath)

        return currentLayer
    }

    /// Add current circle.
    ///
    /// - Parameters:
    ///     - corner: Corner in which add circle
    ///     - currentPosition: current Frame of board
    /// - Returns: a CAShapeLayer with size, origin and form.
    func addCurrentCornerCircle(for corner: RectangleCorner, currentPosition: StereoVisionFrame) -> CAShapeLayer {
        let currentPoint = self.pointCorrected(point: corner.point(for: currentPosition))
        let currentPath = UIBezierPath(arcCenter: currentPoint,
                                       radius: CGFloat(Constants.currentCircleRadius),
                                       startAngle: CGFloat.zero,
                                       endAngle: CGFloat(Double.pi * 2),
                                       clockwise: true)
        let currentLayer = CAShapeLayer()
        createCurrentLayer(layer: currentLayer,
                           path: currentPath.cgPath)

        return currentLayer
    }

    /// Reflects to the point in renderView.
    ///
    /// - Parameters:
    ///     - point: Point in renderView
    /// - Returns: a CGPoint describing the position of layer in renderView.
    func pointCorrected(point: CGPoint) -> CGPoint {
        return CGPoint(x: point.x * renderView.frame.size.width,
                       y: point.y * renderView.frame.size.height)
    }

    /// Add green ball position.
    ///
    /// - Parameters:
    ///     - rotation: Rotation of the ball
    ///     - frame: frame of the ball
    func ballCorrected(rotation: StereoVisionRotation, frame: StereoVisionFrame) -> CGPoint {
        var newCenter: CGPoint = CGPoint()
        let ratioX: Double = rotation.xAngle / Constants.ballRatioAngle
        let ratioY: Double = rotation.yAngle / Constants.ballRatioAngle
        let rightValueX = (Constants.ballCoeff + ratioX) * (frame.getRightTopVertex().getX() + frame.getRightBottomVertex().getX())
        let leftValueX = (Constants.ballCoeff - ratioX) * (frame.getLeftTopVertex().getX() + frame.getLeftBottomVertex().getX())
        newCenter.x = CGFloat((rightValueX + leftValueX) / Constants.ballDivider)
        let bottomValueY = (Constants.ballCoeff + ratioY) * (frame.getLeftBottomVertex().getY() + frame.getRightBottomVertex().getY())
        let topValueY = (Constants.ballCoeff - ratioY) * (frame.getLeftTopVertex().getY() + frame.getRightTopVertex().getY())
        newCenter.y = CGFloat((bottomValueY + topValueY) / Constants.ballDivider)

        return pointCorrected(point: newCenter)
    }

    /// Draw circle frame and circle fill.
    func configureCircleLayer() {
        let radius = Constants.loaderRadius
        let center = self.view.center
        let startAngle: CGFloat = -.pi / 2
        let endAngle: CGFloat = startAngle + 2 * .pi
        let circleRing = CAShapeLayer()

        circleLayer.strokeColor = ColorName.greenSpring20.color.cgColor
        circleLayer.fillColor = UIColor.clear.cgColor
        circleLayer.lineWidth = CGFloat(radius)
        circleLayer.path = UIBezierPath(arcCenter: center,
                                        radius: CGFloat(radius / 2),
                                        startAngle: startAngle,
                                        endAngle: endAngle,
                                        clockwise: true).cgPath
        circleLayer.strokeEnd = 0.0
        circleRing.fillColor = UIColor.clear.cgColor
        circleRing.strokeColor = ColorName.greenSpring.color.cgColor
        circleRing.lineWidth = CGFloat(Constants.greenCornersBorder)
        circleRing.path = UIBezierPath(arcCenter: center,
                                       radius: CGFloat(radius),
                                       startAngle: -.pi / 2,
                                       endAngle: endAngle,
                                       clockwise: true).cgPath

        view.layer.addSublayer(circleRing)
        view.layer.addSublayer(circleLayer)
        self.requiredPositionLayers.append(contentsOf: [circleRing, circleLayer])
    }

    /// Animate Circle fill and show calibration result after animation.
    func startCircleAnimation(calibrationState: StereoVisionCalibrationProcessState) {
        CATransaction.begin()
        circleLayer.strokeEnd = 1.0
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0.0
        animation.toValue = 1.0
        animation.duration = Constants.loaderAnimationDuration
        circleLayer.add(animation, forKey: nil)
        CATransaction.commit()
    }
}
