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

/// Gallery panorama type choice ViewController.
final class GalleryPanoramaChoiceTypeViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var primaryStackView: UIStackView!
    @IBOutlet private weak var sphereChoiceView: GalleryPanoramaTypeChoiceView!
    @IBOutlet private weak var tinyPlanetChoiceView: GalleryPanoramaTypeChoiceView!
    @IBOutlet private weak var secondaryStackView: UIStackView!
    @IBOutlet private weak var tunnelChoiceView: GalleryPanoramaTypeChoiceView!
    @IBOutlet private weak var customChoiceView: GalleryPanoramaTypeChoiceView!
    @IBOutlet private weak var generateButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryPanoramaViewModel?
    private var index: Int = 0

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryPanoramaChoiceTypeViewController.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryMediaViewModel,
                            index: Int) -> GalleryPanoramaChoiceTypeViewController {
        let viewController = StoryboardScene.GalleryPanorama.initialScene.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = GalleryPanoramaViewModel(galleryViewModel: viewModel)
        viewController.index = index

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupChoicesModels()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaChoiceTypeViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        guard let galleryViewModel = viewModel?.galleryViewModel,
            let currentMedia = galleryViewModel.getMedia(index: index) else {
                return
        }

        titleLabel.makeUp(with: .large)
        titleLabel.attributedText = currentMedia.titleAttributedString
        textLabel.makeUp(with: .huge)
        textLabel.text = L10n.galleryPanoramaGenerateQuestion
        generateButton.makeup(with: .large, color: ColorName.white)
        generateButton.setTitle(L10n.commonStart, for: .normal)
        generateButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        generateButton.isEnabled = viewModel?.selectedPanoramaMediaType != nil
        generateButton.alpha = generateButton.isEnabled ? 1.0 : 0.5
    }

    /// Sets up models associated with the choices view.
    func setupChoicesModels() {
        self.sphereChoiceView.model = GalleryPanoramaTypeChoiceModel(image: Asset.Gallery.Panorama.sphereChoice.image,
                                                                     text: L10n.galleryPanoramaSphere,
                                                                     highlighted: viewModel?.selectedPanoramaMediaType == .sphere)
        self.tinyPlanetChoiceView.model = GalleryPanoramaTypeChoiceModel(image: Asset.Gallery.Panorama.tinyPlanetChoice.image,
                                                                         text: L10n.galleryPanoramaTinyPlanet,
                                                                         highlighted: viewModel?.selectedPanoramaMediaType == .tinyPlanet)
        self.tunnelChoiceView.model = GalleryPanoramaTypeChoiceModel(image: Asset.Gallery.Panorama.tunnelChoice.image,
                                                                     text: L10n.galleryPanoramaTunnel,
                                                                     highlighted: viewModel?.selectedPanoramaMediaType == .tunnel)
        self.customChoiceView.model = GalleryPanoramaTypeChoiceModel(image: Asset.Gallery.Panorama.customChoice.image,
                                                                     icon: Asset.Gallery.Panorama.customEdit.image,
                                                                     text: L10n.galleryPanoramaCustom,
                                                                     highlighted: viewModel?.selectedPanoramaMediaType == .custom)
    }
}

// MARK: - Actions
private extension GalleryPanoramaChoiceTypeViewController {
    /// Redirect to the previous screen.
    @IBAction func backButtonTouchedUpInside() {
        coordinator?.dismissPanoramaGenerationScreen()
    }

    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: GalleryPanoramaTypeChoiceView) {
        switch view {
        case sphereChoiceView:
            viewModel?.selectedPanoramaMediaType = .sphere
        case tinyPlanetChoiceView:
            viewModel?.selectedPanoramaMediaType = .tinyPlanet
        case tunnelChoiceView:
            viewModel?.selectedPanoramaMediaType = .tunnel
        default:
            viewModel?.selectedPanoramaMediaType = .custom
        }
        setupUI()
        setupChoicesModels()
    }

    /// Function called when the generate button is clicked.
    @IBAction func generateButtonTouchedUpInside() {
        guard let viewModel = viewModel else { return }

        coordinator?.showPanoramaQualityChoiceScreen(viewModel: viewModel, index: index)
    }
}
