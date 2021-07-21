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

/// View Controller used to display details about Remote.
final class RemoteDetailsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var bgView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    // MARK: - Private Properties
    private weak var coordinator: RemoteCoordinator?
    private var deviceViewController: RemoteDetailsDeviceViewController?
    private var informationViewController: RemoteDetailsInformationsViewController?
    private var buttonsViewController: RemoteDetailsButtonsViewController?

    // MARK: - Setup
    static func instantiate(coordinator: RemoteCoordinator) -> RemoteDetailsViewController {
        let viewController = StoryboardScene.RemoteDetails.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        setupOrientationObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.remoteControlDetails,
                             logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension RemoteDetailsViewController {
    @objc func backButtonTouchedUpInside(_ sender: UIButton) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyCommonButton.back, logType: .simpleButton)
        coordinator?.dismissChildCoordinator()
    }
}

// MARK: - Private Funcs
private extension RemoteDetailsViewController {
    /// Inits the view.
    func initView() {
        addCloseButton(onTapAction: #selector(backButtonTouchedUpInside(_:)))
        setupViewControllers()
        bgView.backgroundColor = ColorName.white10.color
        updateStackView()
    }

    /// Sets up observer for orientation change.
    func setupOrientationObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateStackView),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }

    /// Sets up view controllers.
    func setupViewControllers() {
        guard let strongCoordinator = coordinator else { return }

        buttonsViewController = RemoteDetailsButtonsViewController.instantiate(coordinator: strongCoordinator)
        deviceViewController = RemoteDetailsDeviceViewController.instantiate(coordinator: strongCoordinator)

        let remoteInfosViewModel = RemoteDetailsInformationsViewModel()
        informationViewController = RemoteDetailsInformationsViewController.instantiate(coordinator: strongCoordinator,
                                                                                        viewModel: remoteInfosViewModel)
        [buttonsViewController, deviceViewController, informationViewController].forEach { viewController in
            guard let strongViewController = viewController else { return }

            addChild(strongViewController)
        }

    }

    /// Updates stack view.
    @objc func updateStackView() {
        stackView.removeSubViews()

        guard let infoView = informationViewController?.view,
              let buttonView = buttonsViewController?.view,
              let deviceView = deviceViewController?.view else {
            return
        }

        if UIApplication.isLandscape {
            [infoView,
             deviceView,
             buttonView].forEach { view in
                stackView.addArrangedSubview(view)
             }
        } else {
            [deviceView,
             infoView,
             buttonView].forEach { view in
                stackView.addArrangedSubview(view)
             }
        }
    }
}
