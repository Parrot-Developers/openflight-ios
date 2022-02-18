//    Copyright (C) 2021 Parrot Drones SAS
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

/// A `UIProgressView` subclass allowing indeterminate progress animation.
///
/// This progressView can be configured in `.indeterminate` mode in order
/// to animate an unknown duration progress with a looping `progressTintColor`
/// gradient.
/// Default progress animation is available via `.determinate` type.
@IBDesignable
class ActivityProgressView: UIProgressView {

    enum ProgressType { case determinate, indeterminate }

    enum AnimationType { case restart, reverse }

    // MARK: - Public Properties
    /// The progress bar type.
    var type: ProgressType = .indeterminate {
        didSet {
            // Stop indeterminate animation when switching to `determinate` type.
            guard type == .determinate else { return }
            stopAnimating()
        }
    }

    /// IBInspectable property for indeterminate type toggling in Interface Builder.
    @available(*,
                unavailable,
                message: "Interface Builder property. Use `type`.")
    @IBInspectable
    var indeterminate: Bool = true {
        willSet {
            type = newValue ? .indeterminate : .determinate
        }
    }

    /// Animation duration. Time in seconds for the progress indicator to travel the whole bar.
    var animationDuration: TimeInterval = 1 {
        didSet {
            guard isAnimating else { return }
            stopAnimating()
            startAnimating()
        }
    }

    /// IBInspectable property for animation duration setting in Interface Builder.
    @available(*,
                unavailable,
                message: "Interface Builder property. Use `animationDuration`.")
    @IBInspectable
    var indeterminateAnimationDuration: Double = 1 {
        willSet {
            animationDuration = newValue
        }
    }

    /// The animation type.
    var animationType: AnimationType = .restart {
        didSet {
            // Restart the animation.
            guard type == .indeterminate else { return }
            stopAnimating()
            startAnimating()
        }
    }

    /// The minimum width for the indeterminate progress view indicator.
    var indeterminateProgressViewMinimumWidth: CGFloat? {
        didSet {
            updateIndeterminateProgressView()
        }
    }

    // MARK: - Overrided Properties
    override var frame: CGRect {
        didSet {
            updateIndeterminateProgressView()
        }
    }

    override var progressTintColor: UIColor? {
        didSet {
            updateIndeterminateProgressView()
        }
    }

    override var tintColor: UIColor? {
        didSet {
            updateIndeterminateProgressView()
        }
    }

    override var trackTintColor: UIColor? {
        didSet {
            updateIndeterminateProgressView()
        }
    }

    // MARK: - Private Properties
    /// The indeterminate progress view used for the animation.
    private let indeterminateProgressView = UIView()

    /// Indicates whether indeterminate progress bar is animating
    private var isAnimating: Bool = false

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateIndeterminateProgressView()
    }

    /// Override `setProgress` method in order to prevent any external progress update
    /// when current type is `.indeterminate`.
    override func setProgress(_ progress: Float, animated: Bool) {
        guard type == .determinate else { return }
        super.setProgress(progress, animated: animated)
    }

    private func setupView() {
        addSubview(indeterminateProgressView)
        indeterminateProgressView.clipsToBounds = true
        clipsToBounds = true
        updateIndeterminateProgressView()
    }

    func startAnimating() {
        guard type == .indeterminate,
              !isAnimating else { return }
            super.setProgress(0, animated: false)
        animateIndeterminateProgress()
        indeterminateProgressView.isHidden = false
        isAnimating = true
    }

    func stopAnimating() {
        indeterminateProgressView.isHidden = true
        layer.removeAllAnimations()
        isAnimating = false
    }
}

// MARK: - `indeterminateProgressView` UI
extension ActivityProgressView {

    /// Private Constants.
    private enum Constants {
        static let defaultProgressTintColor = ColorName.highlightColor.color
        static let startPoint = CGPoint(x: 0, y: 0.5)
        static let endPoint = CGPoint(x: 1, y: 0.5)
    }

    /// Updates the indeterminate progress view.
    private func updateIndeterminateProgressView() {
        updateIndeterminateProgressViewFrame()
        updateIndeterminateProgressViewGradient()
    }

    /// Updates the indeterminate progress view frame.
    private func updateIndeterminateProgressViewFrame() {
        let width = max(indeterminateProgressViewMinimumWidth ?? 0, bounds.width / 3)
        let progressFrame = CGRect(origin: CGPoint(x: -width,
                                                   y: 0),
                                   size: CGSize(width: width,
                                                height: bounds.height))
        indeterminateProgressView.frame = progressFrame
    }

    /// Updates the indeterminate progress view gradient.
    private func updateIndeterminateProgressViewGradient() {
        indeterminateProgressView.backgroundColor = .clear
        // Remove previous ones.
        indeterminateProgressView.layer
            .sublayers?
            .filter { $0 is CAGradientLayer }
            .forEach { $0.removeFromSuperlayer() }

        let gradient = CAGradientLayer()
        gradient.frame = indeterminateProgressView.bounds
        gradient.colors = [trackTintColor?.withAlphaComponent(0) ?? .clear,
                           progressTintColor ?? tintColor ?? Constants.defaultProgressTintColor,
                           trackTintColor?.withAlphaComponent(0) ?? .clear].map { $0.cgColor }
        gradient.startPoint = Constants.startPoint
        gradient.endPoint = Constants.endPoint

        indeterminateProgressView.layer
            .insertSublayer(gradient, at: 0)
    }
}

// MARK: - Animations
extension ActivityProgressView {

    /// The animation progress view start position.
    private var animationStartOrigin: CGPoint {
        CGPoint(x: -indeterminateProgressView.frame.width, y: 0)
    }

    /// The animation progress view end position.
    private var animationEndOrigin: CGPoint {
        CGPoint(x: bounds.width, y: 0)
    }

    /// Starts the progress view animation.
    private func animateIndeterminateProgress() {
        if animationType == .restart {
            indeterminateProgressView.frame.origin = animationStartOrigin
        }
        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: [.curveLinear]) { [weak self] in
            guard let animationStartOrigin = self?.animationStartOrigin else { return }
            guard let animationEndOrigin = self?.animationEndOrigin else { return }
            guard let animationType = self?.animationType else { return }

            let targetPoint: CGPoint
            if animationType == .reverse {
                targetPoint = self?.indeterminateProgressView.frame.origin == animationStartOrigin
                ? animationEndOrigin
                : animationStartOrigin
            } else {
                targetPoint = animationEndOrigin
            }
            self?.indeterminateProgressView.frame.origin = targetPoint
        } completion: { [weak self] _ in
            if self?.isAnimating == true { self?.animateIndeterminateProgress() }
        }
    }
}
