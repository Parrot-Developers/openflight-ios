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

import OpenGLES
import CoreMotion
import OpenFlightCore

/// Gallery panorama ViewController.

final class GalleryPanoramaViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak private var panoramaView: PhotoPanoView!
    @IBOutlet weak private var gyroscopeButton: UIButton!
    @IBOutlet weak private var exitButton: UIButton!

    // MARK: - Internal properties
    var panoramaUrl: URL?
    var startAnimationEnabled: Bool = false
    var triggerAnimation: Bool = false
    var gyroEnabled: Bool = false
    var fovControl: PhotoPanoViewFovControl = .rectilinear
    var gridDivisions: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var motionManager: CMMotionManager?
    private var rotateGesture: UIRotationGestureRecognizer?
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    private var singleTapGesture: UITapGestureRecognizer?
    private var displaylink: CADisplayLink?
    private var panoramaViewIsSetup: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let deviceMotionUpdateInterval = 1.0 / 60.0
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    ///     - url: Url of the panorama
    /// - Returns: a GalleryPanoramaViewController.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryMediaViewModel,
                            url: URL) -> GalleryPanoramaViewController {
        let viewController = StoryboardScene.GalleryMediaPlayerViewController.galleryPanoramaViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.panoramaUrl = url

        return viewController
    }

    // MARK: - Deinit
    deinit {
        motionManager?.stopDeviceMotionUpdates()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        initGestures()
        removeBackButtonText()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !panoramaViewIsSetup {
            setUpPanoramaView()
            panoramaViewIsSetup = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addDisplayLink()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        removeDisplayLink()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        panoramaView.touchDown()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        panoramaView.touchUp()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        gyroscopeButton.cornerRadiusedWith(backgroundColor: ColorName.black60.color, radius: Style.largeCornerRadius)
        exitButton.cornerRadiusedWith(backgroundColor: ColorName.black60.color, radius: Style.largeCornerRadius)
    }

    /// Init gestures.
    func initGestures() {
        motionManager = CMMotionManager()

        var gestures: [UIGestureRecognizer?] = []
        rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(self.handleRotate(recognizer:)))
        gestures.append(rotateGesture)
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(recognizer:)))
        gestures.append(panGesture)
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(recognizer:)))
        gestures.append(pinchGesture)
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDoubleTap(recognizer:)))
        doubleTapGesture?.numberOfTapsRequired = 2
        gestures.append(doubleTapGesture)
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleSingleTap(recognizer:)))
        singleTapGesture?.numberOfTapsRequired = 1
        gestures.append(singleTapGesture)

        gestures.forEach { gesture in
            panoramaView.addGestureRecognizer(gesture)
            gesture?.cancelsTouchesInView = false
            gesture?.delegate = self
        }
    }

    /// Setup panorama view.
    func setUpPanoramaView() {
        guard let context = EAGLContext(api: .openGLES3),
            let panoramaUrl = panoramaUrl else {
                return
        }

        panoramaView.setup(context, fovControl: fovControl, gridDivisions: Int32(gridDivisions))
        panoramaView.setPanorama(panoramaUrl.path, enableAnimation: startAnimationEnabled, triggerAnimation: triggerAnimation)
        motionManager?.deviceMotionUpdateInterval = Constants.deviceMotionUpdateInterval
        motionManager?.showsDeviceMovementDisplay = true
        motionManager?.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(addDisplayLink),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(removeDisplayLink),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }

    @objc func addDisplayLink() {
        displaylink = CADisplayLink(target: self, selector: #selector(render))
        displaylink?.add(to: .current, forMode: RunLoop.Mode.default)
    }

    @objc func removeDisplayLink() {
        displaylink?.invalidate()
        displaylink = nil
    }

    @objc func render(displaylink: CADisplayLink) {
        if gyroEnabled {
            if let data = motionManager?.deviceMotion {
                let quaternion = data.attitude.quaternion
                let orientation = UIApplication.shared.statusBarOrientation
                panoramaView.setQuaternion(quaternion, orientation: orientation)
            }
        }
        panoramaView.display()
    }

    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panoramaView.startPan(recognizer.numberOfTouches)
        case .changed:
            panoramaView.updatePan(recognizer.translation(in: panoramaView))
        case .ended:
            panoramaView.endPan()
        case .cancelled:
            panoramaView.endPan()
        default:
            break
        }
    }

    @objc func handlePinch(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panoramaView.startPinch()
        case .changed:
            panoramaView.updatePinch(recognizer.scale)
        case .ended:
            panoramaView.endPinch()
        case .cancelled:
            panoramaView.endPinch()
        default:
            break
        }
    }

    @objc func handleRotate(recognizer: UIRotationGestureRecognizer) {
        switch recognizer.state {
        case .began:
            panoramaView.startRotation()
        case .changed:
            panoramaView.updateRotation(recognizer.rotation)
        case .ended:
            panoramaView.endRotation()
        case .cancelled:
            panoramaView.endRotation()
        default:
            break
        }
    }

    @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            panoramaView.doubleTap()
            panoramaView.touchUp()
        default:
            break
        }
    }

    @objc func handleSingleTap(recognizer: UITapGestureRecognizer) {
        guard let viewModel = viewModel else { return }

        viewModel.toggleShouldHideControls()
        gyroscopeButton.isHidden = viewModel.shouldHideControls
        exitButton.isHidden = viewModel.shouldHideControls
    }
}

// MARK: - Actions
private extension GalleryPanoramaViewController {
    @IBAction func gyroscopeButtonTouchedUpInside(_ sender: AnyObject) {
        gyroEnabled.toggle()
        gyroscopeButton.setImage(gyroEnabled ? Asset.Gallery.Panorama.icGyroscopeHighlighted.image : Asset.Gallery.Panorama.icGyroscope.image, for: .normal)
    }

    @IBAction func exitButtonTouchedUpInside(_ sender: AnyObject) {
        coordinator?.dismissPanoramaVisualisationScreen()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension GalleryPanoramaViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture || otherGestureRecognizer == panGesture {
            return false
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIButton)
    }
}
