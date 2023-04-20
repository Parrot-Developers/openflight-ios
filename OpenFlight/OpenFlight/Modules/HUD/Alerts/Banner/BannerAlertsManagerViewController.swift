//    Copyright (C) 2022 Parrot Drones SAS
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

import Combine
import AudioToolbox

/// A `PassThroughViewController` for banner alerts management.
class BannerAlertsManagerViewController: PassThroughViewController {
    /// The view model.
    var viewModel: BannerAlertsManagerViewModel!

    // MARK: Private Properties

    /// The main banner alerts container stack view.
    private let mainStackView = PassThroughBasicStackView()
    /// The non-mandatory banner alerts stack view.
    private let alertsStackView = PassThroughBasicStackView()
    /// The mandatory banner alerts stack view.
    private let mandatoryStackView = PassThroughBasicStackView()
    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    private enum Constants {
        /// The animation yOffset.
        static let animationYOffset: CGFloat = 16
    }

    // MARK: Init

    /// Constructor.
    ///
    /// - Parameter viewModel: the banner alerts manager view model
    /// - Returns: the banner alerts manager view controller with provided view model
    static func instantiate(viewModel: BannerAlertsManagerViewModel) -> BannerAlertsManagerViewController {
        let viewController = BannerAlertsManagerViewController()
        viewController.viewModel = viewModel
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        observeViewModel()
    }

    /// Observes view model's updates.
    private func observeViewModel() {
        viewModel.$mode.removeDuplicates()
            .combineLatest(viewModel.$banners.removeDuplicates())
            .sink { [weak self] (mode, banners) in
                self?.displayAlerts(banners, mode: mode)
            }
            .store(in: &cancellables)

        viewModel.$container.removeDuplicates()
            .sink { [weak self] frame in
                self?.setupContainer(frame: frame)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private Functions

private extension BannerAlertsManagerViewController {
    /// Sets up view.
    func setupView() {
        // Mandatory alerts stack view.
        mandatoryStackView.axis = .vertical
        mandatoryStackView.spacing = 0
        mandatoryStackView.alignment = .center

        // Non-mandatory alerts stack view.
        alertsStackView.axis = .vertical
        alertsStackView.spacing = 0
        alertsStackView.alignment = .center

        // Add an empty view in order to avoid unwanted frame animation when
        // inserting an alert into an empty stack view.
        alertsStackView.addArrangedSubview(UIView())
        mandatoryStackView.addArrangedSubview(UIView())

        // Main container stack view.
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.addArrangedSubview(mandatoryStackView)
        mainStackView.addArrangedSubview(alertsStackView)
        view.addSubview(mainStackView)

        // Add constraints. `mainStackView` is:
        //   - limited by superview width,
        //   - horizontally centered in superview,
        //   - anchored to top.
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor,
                                                   constant: Layout.mainPadding(isRegularSizeClass)),
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }

    /// Sets up container frame.
    ///
    /// - Parameter frame: the frame to set the container to
    func setupContainer(frame: CGRect) {
        view.frame = frame
        UIView.animate(Style.shortAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}

private extension BannerAlertsManagerViewController {
    /// Displays banner alertes on screen for a specific mode.
    ///
    /// - Parameters:
    ///    - alerts: the banner alerts to display
    ///    - mode: the banner alert display mode
    func displayAlerts(_ alerts: [AnyBannerAlert], mode: BannerAlertMode) {
        let banners = mode == .hidden ? [] : alerts

        // Add alerts in dedicated stack views.
        let mandatoryAlerts = banners.filter { $0.severity == .mandatory }
        let alerts = banners.filter { !mandatoryAlerts.contains($0) }
        updateBanners(alerts, in: alertsStackView)
        updateBanners(mandatoryAlerts, in: mandatoryStackView)

        // Remove spacing between `mandatoryStackView` and `alertsStackView` if one of them is empty
        // in order to ensure `mainStackView` is correctly centered.
        mainStackView.spacing = alerts.isEmpty || mandatoryAlerts.isEmpty ? 0 : BannerAlertConstants.defaultSpacing
    }

    /// Updates stack view content with provided banners array.
    ///
    /// - Parameters:
    ///    - banners: the banner alerts to display
    ///    - stackView: the stack view to update
    func updateBanners(_ banners: [AnyBannerAlert], in stackView: UIStackView) {
        // Get ids of banners currently displayed in stackView.
        let currentBannerIds = stackView
            .arrangedSubviews
            .filter { $0 is BannerAlertView }
            .map { $0.tag }

        // Get ids of banners to be displayed.
        let newBannerIds = banners.map { $0.hashValue }

        guard newBannerIds != currentBannerIds else { return }

        // Filter banners to remove/add.
        let bannerIdsToRemove = currentBannerIds.filter { !newBannerIds.contains($0) }
        let bannerIdsToAdd = newBannerIds.filter { !currentBannerIds.contains($0) }
        let bannersToAdd = banners.filter { bannerIdsToAdd.contains($0.hashValue) }

        for banner in bannersToAdd {
            addBanner(banner, in: stackView)
        }

        // Dispatch banners removal in order to avoid unwanted slide transitions when
        // simultaneously adding/removing banners.
        DispatchQueue.main.async {
            for identifier in bannerIdsToRemove {
                self.removeBanner(with: identifier, from: stackView)
            }
        }
    }

    /// Adds a banner to provided stack view.
    ///
    /// - Parameters:
    ///    - banner: the banner to add
    ///    - stackView: the stack view to add the banner to
    func addBanner(_ banner: AnyBannerAlert, in stackView: UIStackView) {
        // Play haptic and/of system sound feedback if relevant.
        playFeedbackIfNeeded(banner)

        // Create new banner alert view according to parameters.
        let viewModel = BannerAlertViewModel(content: banner.content, style: banner.style)
        let alertView = BannerAlertView(viewModel: viewModel)
        alertView.tag = banner.hashValue
        stackView.insertArrangedSubview(alertView, at: 0)

        alertView.alpha = 0
        alertView.isHidden = true
        alertView.transform = .init(translationX: 0, y: Constants.animationYOffset)
        UIView.animate(Style.shortAnimationDuration) {
            alertView.isHidden = false
            alertView.transform = .identity
            alertView.alpha = 1
        }
    }

    /// Removes banner with a specific uid from provided stack view.
    ///
    /// - Parameters:
    ///    - uid: the uid of the banner to remove
    ///    - stackView: the stack view to remove the banner from
    func removeBanner(with uid: Int, from stackView: UIStackView) {
        guard let alertView = stackView.viewWithTag(uid) else { return }

        let isLastBanner = stackView
            .arrangedSubviews
            .filter { $0 is BannerAlertView }
            .count == 1

        // Immediately hide banner if not the last one.
        // (New/existing one(s) will be animated, more satistying visually.)
        if !isLastBanner {
            alertView.alpha = 0
        }
        UIView.animate(Style.shortAnimationDuration) {
            if isLastBanner {
                // Last banner => animate fading and translation.
                alertView.transform = .init(translationX: 0, y: Constants.animationYOffset)
                alertView.alpha = 0
            }
            alertView.isHidden = true
        } completion: { _ in
            alertView.removeFromSuperview()
        }
    }

    /// Plays haptic and/or system sound feedback if corresponding banner's parameters are set.
    ///
    /// - Parameter banner: the banner to get feedback parameters from
    func playFeedbackIfNeeded(_ banner: AnyBannerAlert) {
        // Do not play any feedback if app is not active or view controller is not displayed on screen
        guard UIApplication.isAppActive, isVisible() else { return }

        if let feedbackType = banner.behavior.feedbackType {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(feedbackType)
        }

        if let systemSoundId = banner.behavior.systemSoundId {
            AudioServicesPlaySystemSound(SystemSoundID(systemSoundId))
        }
    }
}
