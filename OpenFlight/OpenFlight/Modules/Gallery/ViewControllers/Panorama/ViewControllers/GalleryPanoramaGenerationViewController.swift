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
import Combine

/// Panorama download and generation ViewController.
final class GalleryPanoramaGenerationViewController: UIViewController {
    var viewModel: GalleryPanoramaViewModel?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var cancelButton: InsetHitAreaButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var mediaTitleView: GalleryMediaTitleView!
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var progressLabel: UILabel!
    @IBOutlet private weak var stepsStackView: UIStackView!

    // MARK: - Private Properties
    private var index: Int = 0

    // MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        observeViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel?.startProcessAsked()
    }

    override var prefersStatusBarHidden: Bool { true }

    /// Observe panorama VM updates.
    func observeViewModel() {
        viewModel?.$generationProgress
            .sink { [unowned self] progress in
                updateProgressView(progress)
            }
            .store(in: &cancellables)

        viewModel?.$generationStepModels
            .sink { [unowned self] models in
                updateSteps(models)
            }
            .store(in: &cancellables)
    }

    /// Inits view controller.
    ///
    /// - Parameters:
    ///    - viewModel: gallery panorama viewModel.
    ///    - index: Media index in the gallery media array
    /// - Returns: a GalleryPanoramaGenerationViewController.
    static func instantiate(viewModel: GalleryPanoramaViewModel,
                            index: Int) -> GalleryPanoramaGenerationViewController {
        let viewController = StoryboardScene.GalleryPanorama.galleryPanoramaGenerationViewController.instantiate()
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }
}

// MARK: - Actions
private extension GalleryPanoramaGenerationViewController {
    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        viewModel?.cancelButtonTapped()
    }
}

// MARK: - Private Funcs

// UI Init
private extension GalleryPanoramaGenerationViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        guard let galleryMediaViewModel = viewModel?.galleryMediaViewModel,
              let currentMedia = galleryMediaViewModel.getMedia(index: index) else {
            return
        }

        mediaTitleView.model = currentMedia
        progressLabel.makeUp(with: .huge, and: ColorName.defaultTextColor)
        progressLabel.font = FontStyle.title.font(isRegularSizeClass, monospacedDigits: true)
        titleLabel.makeUp(with: .large, and: ColorName.defaultTextColor)
        titleLabel.attributedText = currentMedia.titleAttributedString

        initStepsStackView()
    }

    /// Inits steps stackView according to model content.
    func initStepsStackView() {
        guard let viewModel = viewModel else { return }

        stepsStackView.removeSubViews()
        for model in viewModel.generationStepModels {
            let view = GalleryPanoramaStepView()
            view.model = model
            stepsStackView.addArrangedSubview(view)
        }
    }
}

// UI Update
private extension GalleryPanoramaGenerationViewController {
    func updateProgressView(_ progress: Float) {
        circleProgressView.setProgress(progress, duration: Style.mediumAnimationDuration)
        // Delay progressLabel update in order to sync it with circleProgress animation end.
        DispatchQueue.main.asyncAfter(deadline: .now() + Style.mediumAnimationDuration) {
            self.progressLabel.text = String(format: "%d%%", Int((progress) * 100))
        }
    }

    func updateSteps(_ models: [GalleryPanoramaStepModel]) {
        guard stepsStackView.arrangedSubviews.count == models.count else { return }

        DispatchQueue.main.async {
            self.circleProgressView.status = self.viewModel?.status.toProgressStatus ?? .inactive
        }
        UIView.animate(withDuration: Style.mediumAnimationDuration, delay: 0, options: .curveEaseOut) {
            for index in 0..<models.count {
                (self.stepsStackView.arrangedSubviews[index] as? GalleryPanoramaStepView)?.model = models[index]
            }
        }
    }
}
