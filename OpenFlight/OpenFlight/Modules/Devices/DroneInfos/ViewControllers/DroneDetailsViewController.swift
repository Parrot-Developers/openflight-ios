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
import GroundSdk

/// View Controller used to display details about drone.
final class DroneDetailsViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var stackView: MainContainerStackView!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!

    // MARK: - Private Properties
    private weak var coordinator: DroneCoordinator?
    private var deviceViewController: DroneDetailsDeviceViewController?
    private var informationViewController: DroneDetailsInformationsViewController?
    private var buttonsViewController: DroneDetailsButtonsViewController?

    // MARK: - Setup
    static func instantiate(coordinator: DroneCoordinator,
                            deviceViewController: DroneDetailsDeviceViewController,
                            informationViewController: DroneDetailsInformationsViewController,
                            buttonsViewController: DroneDetailsButtonsViewController) -> DroneDetailsViewController {
        let viewController = StoryboardScene.DroneDetails.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.deviceViewController = deviceViewController
        viewController.informationViewController = informationViewController
        viewController.buttonsViewController = buttonsViewController

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.log(.screen(LogEvent.Screen.droneDetails))
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension DroneDetailsViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        LogEvent.log(.simpleButton(LogEvent.LogKeyCommonButton.back))
        coordinator?.dismissDroneInfos()
    }
}

// MARK: - Private Funcs
private extension DroneDetailsViewController {
    /// Inits the view.
    func initView() {
        stackView.margins = Layout.infoContainerInnerMargins(isRegularSizeClass)
        modelLabel.text = L10n.droneDetailsDroneInfo
        modelLabel.makeUp(with: .title, color: .defaultTextColor)
        nameLabel.makeUp(with: .current, color: .secondaryTextColor)
        setupViewControllers()
        updateStackView()
    }

    /// Sets up view controllers.
    func setupViewControllers() {
        [buttonsViewController, deviceViewController, informationViewController].forEach { viewController in
            guard let strongViewController = viewController else { return }
            addChild(strongViewController)
        }
    }

    /// Updates stack view.
    func updateStackView() {
        guard let infoView = informationViewController?.view,
              let buttonView = buttonsViewController?.view,
              let deviceView = deviceViewController?.view else {
                  return
              }

        for (index, view) in [infoView, deviceView, buttonView].enumerated() {
            guard let container = stackView.arrangedSubviews[index] as? UIStackView else { continue }
            container.addArrangedSubview(view)
        }
    }
}
