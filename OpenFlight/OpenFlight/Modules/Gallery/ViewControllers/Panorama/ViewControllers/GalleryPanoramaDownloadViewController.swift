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

/// Gallery panorama ViewController to ask for download the media.
final class GalleryPanoramaDownloadViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var downloadImage: UIImageView!
    @IBOutlet weak var downloadInfoLabel: UILabel!
    @IBOutlet private weak var downloadButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private var viewModel: GalleryPanoramaViewModel?
    private var index: Int = 0

    // MARK: - Setup
    /// Inits view controller.
    ///
    /// - Parameters:
    ///    - coordinator: gallery coordinator.
    ///    - viewModel: gallery panorama viewModel.
    ///    - index: Media index in the gallery media array
    /// - Returns: a GalleryPanoramaDownloadViewController
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryPanoramaViewModel,
                            index: Int) -> GalleryPanoramaDownloadViewController {
        let viewController = StoryboardScene.GalleryPanorama.galleryPanoramaDownloadViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryPanoramaDownloadViewController {
    @IBAction func backButtonTouchUpInside(_ sender: Any) {
        self.coordinator?.showGalleryScreen()
    }

    @IBAction func cancelButtonTouchUpInside(_ sender: Any) {
        self.coordinator?.showGalleryScreen()
    }

    @IBAction func downloadButtonTouchUpInside(_ sender: Any) {
        guard let panoramaViewModel = viewModel else { return }

        self.coordinator?.showPanoramaGenerationScreen(viewModel: panoramaViewModel,
                                                       index: index)
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaDownloadViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        guard let galleryViewModel = viewModel?.galleryViewModel,
              let currentMedia = galleryViewModel.getMedia(index: index) else {
            return
        }

        self.navigationController?.setNavigationBarHidden(true, animated: true)

        titleLabel.makeUp(with: .large)
        titleLabel.attributedText = currentMedia.titleAttributedString

        downloadImage.image = Asset.Gallery.Panorama.icDownloadBig.image

        downloadInfoLabel.makeUp(with: .big)
        downloadInfoLabel.text = L10n.galleryPanoramaDownloadWarning

        downloadButton.makeup(color: .greenSpring)
        downloadButton.applyCornerRadius(Style.mediumCornerRadius)
        downloadButton.backgroundColor = ColorName.greenSpring20.color
        downloadButton.tintColor = ColorName.greenSpring20.color
        downloadButton.setTitle(L10n.commonDownload, for: .normal)

        cancelButton.makeup()
        cancelButton.applyCornerRadius(Style.mediumCornerRadius)
        cancelButton.setBorder(borderColor: ColorName.white.color, borderWidth: Style.mediumBorderWidth)
        cancelButton.backgroundColor = .clear
        cancelButton.tintColor = .white
        cancelButton.setTitle(L10n.cancel, for: .normal)
    }
}
