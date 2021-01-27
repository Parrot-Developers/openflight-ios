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
import SafariServices

/// Marketing component choice which redirects user to the corresponding url.
final class MarketingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var marketingComponentsCollectionView: UICollectionView!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var componentModels: [MarketingComponentChoiceModel] = []

    // MARK: - Private Enums
    /// Stores marketing urls.
    private enum MarketingUrlConstants {
        static let product: String = "https://www.parrot.com/fr"
        static let useCases: String = "https://www.parrot.com/fr/domaines-application"
        static let support: String = "https://support.parrot.com/fr/"
    }

    private enum Constants {
        static let productsKey: String = "products"
        static let useCasesKey: String = "useCasesKey"
        static let supportKey: String = "support"
        static let cellSpacing: CGFloat = 23.0
        static let thirdScreen: CGFloat = 3.0
        static let sectionNumber: Int = 1
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> MarketingViewController {
        let viewController = StoryboardScene.MarketingViewController.marketingViewController.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupChoicesModels()
        initView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateView()
        marketingComponentsCollectionView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension MarketingViewController {
    /// Called when user touches the close button.
    @objc func backTouchedUpInside(_ sender: Any) {
        coordinator?.back()
    }
}

// MARK: - Private Funcs
private extension MarketingViewController {
    /// Sets up all the UI for the view controller.
    func initView() {
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.marketingToolbar
        marketingComponentsCollectionView.backgroundColor = .clear
        marketingComponentsCollectionView.register(cellType: MarketingComponentCell.self)
        marketingComponentsCollectionView.dataSource = self
        marketingComponentsCollectionView.delegate = self

        self.addCloseButton(onTapAction: #selector(backTouchedUpInside(_:)),
                            targetView: self.view,
                            style: .backArrow)
        updateView()
    }

    /// Updates the view.
    func updateView() {
        titleLabel.isHidden = !UIApplication.isLandscape
    }

    /// Sets up models associated with the choices view.
    func setupChoicesModels() {
        self.componentModels.append(MarketingComponentChoiceModel(image: Asset.Marketing.icProducts.image,
                                                                  text: L10n.marketingProducts,
                                                                  url: MarketingUrlConstants.product))
        self.componentModels.append(MarketingComponentChoiceModel(image: Asset.Marketing.icUseCases.image,
                                                                  text: L10n.marketingUsecase,
                                                                  url: MarketingUrlConstants.useCases))
        self.componentModels.append(MarketingComponentChoiceModel(image: Asset.Marketing.icSupport.image,
                                                                  text: L10n.marketingSupport,
                                                                  url: MarketingUrlConstants.support))
    }

    /// Opens marketing url.
    ///
    /// - Parameters:
    ///     - url: url's component to open.
    func openMarketingURL(url: String) {
        guard let fullUrl = URL(string: url) else { return }

        let safariVC = SFSafariViewController(url: fullUrl)
        self.coordinator?.navigationController?.present(safariVC, animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource
extension MarketingViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Constants.sectionNumber
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return componentModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = marketingComponentsCollectionView.dequeueReusableCell(for: indexPath) as MarketingComponentCell
        cell.model = componentModels[indexPath.row]

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MarketingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedComponent = componentModels[indexPath.row]
        openMarketingURL(url: selectedComponent.url)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MarketingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat
        let height: CGFloat

        if UIApplication.isLandscape {
            height = collectionView.frame.height
            width = (collectionView.frame.width - 2 * Constants.cellSpacing) / Constants.thirdScreen
        } else {
            width = collectionView.frame.width
            height = (collectionView.frame.height - 2 * Constants.cellSpacing) / Constants.thirdScreen
        }

        return CGSize(width: width, height: height)
    }
}
