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

// MARK: - Internal Enums
/// Stores possible panorama values.
enum PanoramaQuality {
    case good
    case excellent
}

/// Gallery panorama quality choice ViewController.
final class GalleryPanoramaQualityViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var primaryStackView: UIStackView!
    @IBOutlet private weak var mediumQualityChoiceView: GalleryPanoramaQualityChoiceView!
    @IBOutlet private weak var highQualityChoiceView: GalleryPanoramaQualityChoiceView!
    @IBOutlet private weak var secondaryStackView: UIView!
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var firstStepView: GalleryPanoramaStepView!
    @IBOutlet private weak var secondStepView: GalleryPanoramaStepView!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryPanoramaViewModel?
    private var index: Int = 0
    private var photoPano: PhotoPano?
    private var photoPanoProgressTimer: Timer?

    // MARK: - Private Enums
    private enum Constants {
        static let progressTimerDelay = 1.0
        static let fastGenerationText = "18Mp"
        static let highQualityText = "32Mp"
    }

    // MARK: - Setup
    /// Instantiate viewController.
    ///
    /// - Parameters:
    ///    - coordinator: gallery coordinator
    ///    - viewModel: gallery panorama viewModel
    ///    - index: media index in the gallery media array
    /// - Returns: The panorama quality choice view controller.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryPanoramaViewModel,
                            index: Int) -> GalleryPanoramaQualityViewController {
        let viewController = StoryboardScene.GalleryPanorama.galleryPanoramaQuality.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Deinit
    deinit {
        photoPanoProgressTimer?.invalidate()
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

// MARK: - Actions
private extension GalleryPanoramaQualityViewController {
    /// Redirect to the previous screen.
    @IBAction func backButtonTouchedUpInside() {
        coordinator?.dismissPanoramaGenerationScreen()
    }

    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: GalleryPanoramaQualityChoiceView) {
        guard let galleryViewModel = viewModel?.galleryViewModel,
              let panoViewModel = viewModel,
              let currentMedia = galleryViewModel.getMedia(index: index),
              let downloadState = currentMedia.downloadState else {
            return
        }

        // It's necessary to set the selectedPanoramaMediaType before arriving here in case we are generating a panorama 360.
        // If is not, it means the selected media is a panorama 180 therefore we need to set selectedPanoramaMediaType according to media type.
        if panoViewModel.selectedPanoramaMediaType == nil {
            panoViewModel.selectedPanoramaMediaType = currentMedia.type.toPanoramaType
        }

        switch view {
        case highQualityChoiceView:
            viewModel?.selectedPanoramaQuality = .excellent
        default:
            viewModel?.selectedPanoramaQuality = .good
        }

        setupUI()
        setupChoicesModels()

        downloadState == .toDownload
            ? coordinator?.showPanoramaDownloadScreen(viewModel: panoViewModel, index: index)
            : coordinator?.showPanoramaGenerationScreen(viewModel: panoViewModel, index: index)
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaQualityViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        guard let galleryViewModel = viewModel?.galleryViewModel,
              let currentMedia = galleryViewModel.getMedia(index: index) else {
            return
        }

        self.navigationController?.setNavigationBarHidden(true, animated: true)
        progressLabel.makeUp(with: .large)
        titleLabel.makeUp(with: .large)
        titleLabel.attributedText = currentMedia.titleAttributedString
        self.circleProgressView.strokeColor = ColorName.greenSpring.color
    }

    /// Sets up models associated with the choices view.
    func setupChoicesModels() {
        self.mediumQualityChoiceView.model = GalleryPanoramaQualityChoiceModel(icon: Asset.Gallery.Panorama.mediumQualityChoice.image,
                                                                               text: L10n.galleryPanoramaFastGeneration,
                                                                               textColor: .white,
                                                                               subText: Constants.fastGenerationText,
                                                                               subTextColor: .white50)
        self.highQualityChoiceView.model = GalleryPanoramaQualityChoiceModel(icon: Asset.Gallery.Panorama.highQualityChoice.image,
                                                                             text: L10n.galleryPanoramaHighQuality,
                                                                             textColor: .white,
                                                                             subText: Constants.highQualityText,
                                                                             subTextColor: .white50)
        self.firstStepView.model = GalleryPanoramaStepModel(image: Asset.Gallery.Panorama.icDownload.image,
                                                            text: L10n.galleryPanoramaDownloadingFiles,
                                                            textColor: ColorName.white50)
        self.secondStepView.model = GalleryPanoramaStepModel(image: Asset.Gallery.Panorama.icDownload.image,
                                                             text: L10n.galleryPanoramaDownloadingFiles,
                                                             textColor: ColorName.white50)
    }
}
