//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import SwiftyUserDefaults

/// Dedicated view controller to show terms of use screen.
public final class OnboardingTermsOfUseViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var termsTextView: UITextView!
    @IBOutlet private weak var acceptButton: UIButton!
    @IBOutlet private weak var scrollDownView: UIView!
    @IBOutlet private weak var scrollDownLabel: UILabel!

    // MARK: - Private Properties
    private var coordinator: OnboardingCoordinator?
    private var canAcceptTermsOfUse: Bool = false
    private var termsOfUseFileName: String = ""
    private var termsOfUseKey: DefaultsKey<Bool>?

    // MARK: - Private Enums
    private enum Constants {
        static let termsOfUseFileExtension: String = "html"
    }

    // MARK: - Init
    static func instantiate(coordinator: OnboardingCoordinator,
                            fileName: String,
                            termsOfUseKey: DefaultsKey<Bool>) -> OnboardingTermsOfUseViewController {
        let viewController = StoryboardScene.OnboardingTermsOfUse.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.termsOfUseFileName = fileName
        viewController.termsOfUseKey = termsOfUseKey

        return viewController
    }

    // MARK: - Override Funcs
    public override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }

    public override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    public override var prefersStatusBarHidden: Bool {
        return UIApplication.isLandscape
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

// MARK: - Actions
private extension OnboardingTermsOfUseViewController {
    @IBAction func acceptButtonTouchedUpInside(_ sender: Any) {
        guard let termsOfUseKey = termsOfUseKey,
              Defaults[key: termsOfUseKey] == false else {
            goToLocalizationScreen()
            return
        }

        if canAcceptTermsOfUse {
            Defaults[key: termsOfUseKey] = true
            goToLocalizationScreen()
        } else if scrollDownView.isHidden {
            UIView.animate(withDuration: Style.shortAnimationDuration) {
                self.scrollDownView.isHidden = false
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension OnboardingTermsOfUseViewController: UITextViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.height,
           let termsOfUseKey = termsOfUseKey,
           Defaults[key: termsOfUseKey] == false {
            canAcceptTermsOfUse = true
            updateAcceptButtonUI()
            if !scrollDownView.isHidden {
                UIView.animate(withDuration: Style.shortAnimationDuration) {
                    self.scrollDownView.isHidden = true
                }
            }
        }
    }

    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {

        return true
    }
}

// MARK: - Private Funcs
private extension OnboardingTermsOfUseViewController {
    /// Initializes UI and wordings.
    func initUI() {
        updateAcceptButtonUI()
        scrollDownLabel.cornerRadiusedWith(backgroundColor: ColorName.highlightColor.color,
                                           radius: Style.smallCornerRadius)
        scrollDownLabel.layer.masksToBounds = true
        termsTextView.delegate = self
        titleLabel.text = L10n.termsOfUseTitle.localizedUppercase
        acceptButton.setTitle(L10n.termsOfUseAccept, for: .normal)
        scrollDownLabel.text = L10n.termsOfUseScroll
        scrollDownView.isHidden = true

        if let filePath = Bundle.main.url(forResource: termsOfUseFileName,
                                          withExtension: Constants.termsOfUseFileExtension) {
            do {
                let content = try String(contentsOf: filePath)
                termsTextView.setHTMLFromString(text: content)
            } catch {}
        }
    }

    /// Updates accept button when user finishes scrolling to bottom.
    func updateAcceptButtonUI() {
        acceptButton.setTitleColor(canAcceptTermsOfUse ? ColorName.highlightColor.color : ColorName.defaultTextColor.color, for: .normal)
    }

    /// Redirects to localization screen.
    func goToLocalizationScreen() {
        coordinator?.showLocalizationAccessScreen()
    }
}
