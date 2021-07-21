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

// MARK: - Protocols
protocol HUDIndicatorViewControllerNavigation: AnyObject {
    /// Called when pairing should be opened.
    func openPairing()
}

/// Class used to manage indicator on the HUD.
final class HUDIndicatorViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var pairingButton: UIButton!
    @IBOutlet private var indicatorView: UIView!

    // MARK: - Internal Properties
    var indicatorViewControllerNavigation: HUDIndicatorViewControllerNavigation?

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var indicatorViewModel: HUDIndicatorViewModel?
    private var isDroneConnected: Bool = false

    // MARK: - Private Enums
    private enum Constants {
        static let alpha: CGFloat = 1.0
        static let borderWidth: CGFloat = 1.0
        static let animationDuration: Double = 0.2
        static let pairingButtonMarginRatio: CGFloat = 0.1
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> HUDIndicatorViewController {
        let viewController = StoryboardScene.HUDIndicator.initialScene.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        indicatorViewModel = HUDIndicatorViewModel()
        // Update the view when shouldHideIndicator state changes.
        indicatorViewModel?.state.value.shouldHideIndicator.valueChanged = { [weak self] shouldHideIndicator in
            self?.shouldHidePairingView(needToHide: shouldHideIndicator)
        }
        initView()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HUDIndicatorViewController {
    @IBAction func pairingButtonTouchedUpInside(_ sender: Any) {
        indicatorViewControllerNavigation?.openPairing()
    }
}

// MARK: - Private Funcs
private extension HUDIndicatorViewController {
    /// Init pairing view.
    func initView() {
        // Update text.
        pairingButton.setTitle(L10n.pairingHowToConnectTitle, for: .normal)
        pairingButton.setTitleColor(UIColor(named: .greenSpring), for: .normal)
        // Set the radius and the border fot the content view.
        pairingButton.cornerRadiusedWith(backgroundColor: UIColor.clear,
                                         borderColor: UIColor(named: .greenSpring),
                                         radius: Style.largeCornerRadius,
                                         borderWidth: Constants.borderWidth)
        shouldHidePairingView(needToHide: indicatorViewModel?.state.value.shouldHideIndicator.value ?? false)
    }

    /// Change pairing view visibility.
    ///
    /// - Parameters:
    ///    - needToHide: Bool which indicate if we need to hide the view.
    func shouldHidePairingView(needToHide: Bool) {
        self.indicatorView.translatesAutoresizingMaskIntoConstraints = false

        if !needToHide {
            self.indicatorView.isHidden = false
            self.indicatorView.superview?.isUserInteractionEnabled = true // FIXME: Avoid using superview. Use a delegate instead.
        }
        UIView.animate(withDuration: Constants.animationDuration, animations: {
            self.indicatorView.alpha = needToHide ? 0 : 1
        }, completion: { _ in
            if needToHide {
                self.indicatorView.isHidden = true
                self.indicatorView.superview?.isUserInteractionEnabled = false // FIXME: Avoid using superview. Use a delegate instead.
            }
        })
    }
}

// MARK: - HUDIndicatorViewController
extension HUDIndicatorViewController: SplitControlsDelegate {
    func streamSizeDidChange(width: CGFloat) {
        // Hide the pairing view when the stream width is lower than pairing button width with 10% margin for each side.
        let pairingButtonMargin = 2 * Constants.pairingButtonMarginRatio * pairingButton.frame.width
        let needToHidePairingView = width < pairingButton.frame.width + pairingButtonMargin
        switch needToHidePairingView {
        case true:
            indicatorViewModel?.hideIndicatorView()
        default:
            indicatorViewModel?.showIndicatorView()
        }
    }
}
