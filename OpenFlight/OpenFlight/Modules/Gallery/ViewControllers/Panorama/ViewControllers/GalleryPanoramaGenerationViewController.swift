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

/// Panorama download and generation ViewController.
final class GalleryPanoramaGenerationViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
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
    private var mediaListener: GalleryMediaListener?

    // MARK: - Private Enums
    private enum Constants {
        static let progressTimerDelay: TimeInterval = 1.0
        static let firstStepDone: Float = 0.5
        static let downloadProcessDone: Double = 50
    }

    // MARK: - Setup
    /// Inits view controller.
    ///
    /// - Parameters:
    ///    - coordinator: gallery coordinator.
    ///    - viewModel: gallery panorama viewModel.
    ///    - index: Media index in the gallery media array
    /// - Returns: a GalleryPanoramaGenerationViewController.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryPanoramaViewModel,
                            index: Int) -> GalleryPanoramaGenerationViewController {
        let viewController = StoryboardScene.GalleryPanorama.galleryPanoramaGenerationViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Deinit
    deinit {
        photoPanoProgressTimer?.invalidate()
        photoPanoProgressTimer = nil
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupModels()
        setupViewModel()
        downloadMedia()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryPanoramaGenerationViewController {
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        guard let downloadState = viewModel?.galleryViewModel?.getMedia(index: index)?.downloadState,
              let galleryViewModel = viewModel?.galleryViewModel else {
            return
        }

        if downloadState == .downloading {
            galleryViewModel.cancelDownloads()
        }

        photoPano?.abort()
        coordinator?.dismissPanoramaGenerationScreen()
    }
}

// MARK: - Private Funcs
private extension GalleryPanoramaGenerationViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        guard let galleryViewModel = viewModel?.galleryViewModel,
              let currentMedia = galleryViewModel.getMedia(index: index) else {
            return
        }

        /// Forces to hide navigation bar.
        viewModel?.galleryViewModel?.toggleShouldHideControls(forceHide: true)
        progressLabel.makeUp(with: .large)
        titleLabel.makeUp(with: .large)
        titleLabel.attributedText = currentMedia.titleAttributedString
        self.circleProgressView.strokeColor = ColorName.greenSpring.color
        secondaryStackView.isHidden = false
    }

    /// Setup everything related to view model.
    func setupViewModel() {
        mediaListener = self.viewModel?.galleryViewModel?.registerListener(didChange: { [weak self] state in
            self?.circleProgressView.setProgress(state.downloadProgress / 2.0)
            self?.progressLabel.text = String(format: "%d%%", Int((state.downloadProgress / 2.0) * 100))
            if state.downloadProgress == 1.0 && state.downloadStatus == .complete {
                self?.updateSteps()
                self?.generatePanorama()
            }
        })
    }

    /// Sets up models associated with the choices view.
    func setupModels() {
        guard let downloadState = viewModel?.galleryViewModel?.getMedia(index: index)?.downloadState,
              let panoType = viewModel?.selectedPanoramaMediaType else {
            return
        }

        self.firstStepView.model = viewModel?.updatePanoramaGenerationModels(downloadState: downloadState,
                                                                             panoType: panoType).first
        self.secondStepView.model = viewModel?.updatePanoramaGenerationModels(downloadState: downloadState,
                                                                              panoType: panoType).last
    }

    /// Generate the panorama.
    func generatePanorama() {
        // Refresh gallery medias on device.
        self.viewModel?.galleryViewModel?.refreshMedias(source: .mobileDevice)

        guard let viewModel = self.viewModel,
              let currentMediaUid = viewModel.galleryViewModel?.getMedia(index: index)?.uid,
              let mediaFromDevice = viewModel.galleryViewModel?.deviceViewModel?.getMediaFromUid(currentMediaUid),
              let type = viewModel.selectedPanoramaMediaType,
              let quality = viewModel.selectedPanoramaQuality,
              let mediaUrls = mediaFromDevice.urls,
              let mediaFolderPath = mediaFromDevice.folderPath,
              let mediaPrefix = mediaFromDevice.url?.prefix else {
            return
        }

        let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
        let inputs = mediaUrls.filter({!panoramaRelatedEntries.contains(where: $0.lastPathComponent.contains)})
        let width: Int32 = type.width(forQuality: quality)
        let height: Int32 = type.height(forQuality: quality)
        let outputUrl = URL(string: String(mediaFolderPath + mediaPrefix + "-" + type.rawValue + ".JPG"))

        updateSteps()
        photoPano = PhotoPano()
        photoPanoProgressTimer = Timer.scheduledTimer(withTimeInterval: Constants.progressTimerDelay, repeats: true, block: { [weak self] _ in
            guard let photoPano = self?.photoPano else { return }

            let progress = photoPano.progress()
            DispatchQueue.main.async {
                self?.circleProgressView.setProgress(0.5 + (Float(progress) / 2))
                self?.progressLabel.text = String(format: "%d%%", Int(Constants.downloadProcessDone + ((progress / 2) * 100)))
            }
        })

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let photoPano = self?.photoPano else { return }

            _ = photoPano.process(preset: type.toPanoramaPreset,
                                  inputs: inputs,
                                  width: width,
                                  height: height,
                                  output: outputUrl,
                                  estimationIn: nil,
                                  estimationOut: nil,
                                  description: nil) { [weak self] (status) in
                DispatchQueue.main.async {
                    if status == .success {
                        self?.updateSteps(status)
                        self?.coordinator?.dismissPanoramaGenerationScreen()
                    }
                }
            }
        }
    }

    /// Download media.
    func downloadMedia() {
        /// If we are not on SD card we don't need to download.
        guard let galleryViewModel = viewModel?.galleryViewModel,
              let currentMedia = viewModel?.galleryViewModel?.getMedia(index: index) else {
            return
        }

        if currentMedia.downloadState == .toDownload {
            galleryViewModel.downloadMedias([currentMedia], completion: { [weak self] success in
                guard success else { return }

                self?.handleDownloadEnd()
            })
        } else {
            self.circleProgressView.setProgress(Float(Constants.downloadProcessDone) * 100)
            self.progressLabel.text = String(format: "%d%%", Constants.downloadProcessDone * 100)
            generatePanorama()
        }
    }

    /// Handle download end.
    func handleDownloadEnd() {
        let deleteAction = AlertAction(title: L10n.commonDelete,
                                       style: .destructive,
                                       actionHandler: { [weak self] in
                                        self?.deleteCurrentMedia()
                                       })
        let keepAction = AlertAction(title: L10n.commonKeep,
                                     style: .default)
        showAlert(title: L10n.galleryDownloadComplete,
                  message: L10n.galleryDownloadKeep,
                  cancelAction: deleteAction,
                  validateAction: keepAction)
    }

    /// Delete current media.
    func deleteCurrentMedia() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.galleryViewModel?.getMedia(index: index) else {
            return
        }

        viewModel.galleryViewModel?.deleteMedias([currentMedia], completion: { [weak self] success in
            guard success else { return }

            self?.viewModel?.galleryViewModel?.refreshMedias()
        })
    }

    /// Updates step of the panorama processing.
    ///
    /// - Parameters:
    ///    - panoGenerationStatus: current panorama processing status
    func updateSteps(_ panoGenerationStatus: PhotoPanoProcessingStatus? = nil) {
        guard let viewModel = viewModel,
              let panoType = viewModel.selectedPanoramaMediaType,
              let downloadState = viewModel.galleryViewModel?.getMedia(index: index)?.downloadState else {
            return
        }

        self.firstStepView.model = viewModel.updatePanoramaGenerationModels(downloadState: downloadState,
                                                                            panoType: panoType).first
        self.secondStepView.model = viewModel.updatePanoramaGenerationModels(downloadState: downloadState,
                                                                             panoType: panoType).last
    }
}
