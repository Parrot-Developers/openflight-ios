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

// MARK: - Internal Enums
/// Behaviour Info Type Model.
enum BehaviourInfoTypeModel {
    case bankedTurn
    case horizonLine

    var title: String {
        switch self {
        case .bankedTurn:
            return L10n.settingsBehaviourInfosBankedTurn
        case .horizonLine:
            return L10n.settingsBehaviourInfosHorizonLine
        }
    }

    var titleDescription: String {
        switch self {
        case .bankedTurn:
            return L10n.settingsBehaviourBankedTurn
        case .horizonLine:
            return L10n.settingsBehaviourInfosHorizonLineFixed
        }
    }

    var description: String {
        switch self {
        case .bankedTurn:
            return L10n.settingsBehaviourInfosBankedTurnDescription
        case .horizonLine:
            return L10n.settingsBehaviourInfosHorizonLineFixedDescription
        }
    }

    var image: UIImage {
        switch self {
        case .bankedTurn:
            return Asset.Settings.Advanced.Infos.bankedTurn.image
        case .horizonLine:
            return Asset.Settings.Advanced.Infos.horizonFixed.image
        }
    }
}

/// Dedicated view controller to show settings info.
final class SettingsInfoViewController: UIViewController, StoryboardBased {
    // MARK: - Outlets
    @IBOutlet private weak var imageTop: UIImageView!
    @IBOutlet private weak var imageBottom: UIImageView!
    @IBOutlet private weak var rightBackgroundView: UIView! {
        didSet {
            rightBackgroundView.backgroundColor = ColorName.black80.color
        }
    }
    @IBOutlet private weak var leftBackgroundView: UIView! {
        didSet {
            leftBackgroundView.backgroundColor = ColorName.black80.color
        }
    }
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .huge)
        }
    }
    @IBOutlet private weak var titleDescriptionLabelTop: UILabel! {
        didSet {
            titleDescriptionLabelTop.makeUp(with: .huge)
        }
    }
    @IBOutlet private weak var descriptionLabelTop: UILabel! {
        didSet {
            descriptionLabelTop.makeUp(with: .big)
        }
    }
    @IBOutlet private weak var titleDescriptionLabelBottom: UILabel! {
        didSet {
            titleDescriptionLabelBottom.makeUp(with: .huge)
            titleDescriptionLabelBottom.text = L10n.settingsBehaviourInfosHorizonLineFollow
        }
    }
    @IBOutlet private weak var descriptionLabelBottom: UILabel! {
        didSet {
            descriptionLabelBottom.makeUp(with: .big)
            descriptionLabelBottom.text = L10n.settingsBehaviourInfosHorizonLineFollowDescription
        }
    }
    @IBOutlet private weak var imageTopHeighConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var coordinator: SettingsCoordinator?
    private var infoType: BehaviourInfoTypeModel = BehaviourInfoTypeModel.bankedTurn

    // MARK: - Private Enums
    private enum Constants {
        static let bankedImageScreenRatio: CGFloat = 0.3
    }

    // MARK: - Init
    static func instantiate(coordinator: SettingsCoordinator, infoType: BehaviourInfoTypeModel) -> SettingsInfoViewController {
        let viewController = StoryboardScene.SettingsInfoViewController.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.infoType = infoType

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white
        // Setup content regarding info type.
        self.titleLabel.text = infoType.title
        self.titleDescriptionLabelTop.text = infoType.titleDescription
        self.descriptionLabelTop.text = infoType.description
        self.imageTop.image = infoType.image

        if infoType == .bankedTurn {
            // BankedTurn do not need bottom views.
            self.imageBottom.isHidden = true
            self.titleDescriptionLabelBottom.isHidden = true
            self.descriptionLabelBottom.isHidden = true
            self.imageTopHeighConstraint.constant = self.view.frame.height * Constants.bankedImageScreenRatio
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        LogEvent.logAppEvent(screen: infoType == .bankedTurn
                                ? LogEvent.EventLoggerScreenConstants.settingsBankedTurnInfo
                                : LogEvent.EventLoggerScreenConstants.settingsHorizonLineInfo,
                             logType: .screen)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension SettingsInfoViewController {
    /// Close action.
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        self.coordinator?.back()
    }
}
