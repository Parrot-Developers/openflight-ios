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
import GroundSdk

/// View Controller used to format SD card.

final class GalleryFormatSDCardViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var backgroundButton: UIButton!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var primaryLabel: UILabel!
    @IBOutlet private weak var secondaryLabel: UILabel!
    @IBOutlet private weak var choicesStackView: UIStackView!
    @IBOutlet private weak var quickFormatChoiceView: GalleryFormatSDCardChoiceView!
    @IBOutlet private weak var fullFormatChoiceView: GalleryFormatSDCardChoiceView!
    @IBOutlet private weak var formattingView: UIView!
    @IBOutlet private weak var formattingImageView: UIImageView!
    @IBOutlet private weak var circleProgressView: CircleProgressView!
    @IBOutlet private weak var firstStepView: GalleryFormatSDCardStepView!
    @IBOutlet private weak var secondStepView: GalleryFormatSDCardStepView!
    @IBOutlet private weak var thirdStepView: GalleryFormatSDCardStepView!

    // MARK: - Private Properties
    /// The formatting view model.
    private var viewModel: GalleryFormatSDCardViewModel!
    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The confirmation alert. Needs to be able to be dynamically dismissed if formatting state changes.
    private var confirmationAlert: AlertViewController?

    // MARK: - Setup
    /// Instantiates view controller.
    ///
    /// - Parameter viewModel: the formatting view model
    /// - Returns: a `GalleryFormatSDCardViewController`
    static func instantiate(viewModel: GalleryFormatSDCardViewModel) -> GalleryFormatSDCardViewController {
        let viewController = StoryboardScene.GalleryFormatSDCard.initialScene.instantiate()
        viewController.viewModel = viewModel

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupChoicesModels()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: Style.mediumAnimationDuration) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryFormatSDCardViewController {
    /// Function called when a choice view is clicked.
    @IBAction func choiceViewTouchedUpInside(_ view: GalleryFormatSDCardChoiceView) {
        showConfirmationPopup(type: view == quickFormatChoiceView ? .quick : .full)
    }

    /// Function called when the back button is clicked.
    @IBAction func backButtonTouchedUpInside(_ sender: Any) {
        close()
    }

    /// Function called when the background button is clicked.
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        close()
    }
}

// MARK: - Private Funcs
private extension GalleryFormatSDCardViewController {
    /// Sets up all the UI for the view controller.
    func setupUI() {
        primaryLabel.text = L10n.galleryFormatSdCard
        primaryLabel.font = FontStyle.title.font(isRegularSizeClass)

        secondaryLabel.font = FontStyle.readingText.font(isRegularSizeClass)
        secondaryLabel.textColor = ColorName.disabledTextColor.color
        secondaryLabel.text = L10n.galleryFormatDataErased
        mainView.applyCornerRadius(Style.largeCornerRadius, maskedCorners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        circleProgressView.bgStokeColor = ColorName.whiteAlbescent.color
        circleProgressView.strokeColor = ColorName.highlightColor.color
        quickFormatChoiceView.customCornered(corners: [.allCorners],
                                             radius: Style.largeCornerRadius,
                                             backgroundColor: .white,
                                             borderColor: .clear)
        fullFormatChoiceView.customCornered(corners: [.allCorners],
                                            radius: Style.largeCornerRadius,
                                            backgroundColor: .white,
                                            borderColor: .clear)
    }

    /// Binds the views to the view model.
    func bindViewModel() {
        viewModel.$canClose.removeDuplicates()
            .sink { [weak self] canClose in
                self?.updateCloseModalState(canClose: canClose)
            }
            .store(in: &cancellables)

        viewModel.$formattingState
            .sink { [weak self] state in
                self?.updateFormattingState(with: state)
            }
            .store(in: &cancellables)
    }

    /// Sets up models associated with the choices view.
    func setupChoicesModels() {
        quickFormatChoiceView.model = GalleryFormatSDCardChoiceModel(image: Asset.Common.Icons.icSdCardFormatQuick.image,
                                                                     text: L10n.galleryFormatQuick,
                                                                     textColor: ColorName.defaultTextColor)
        fullFormatChoiceView.model = GalleryFormatSDCardChoiceModel(image: Asset.Common.Icons.icSdCardFormatFull.image,
                                                                    text: L10n.galleryFormatFull,
                                                                    textColor: ColorName.defaultTextColor)
        firstStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icErasing.image,
                                                           text: L10n.galleryFormatErasingPartition,
                                                           textColor: ColorName.disabledTextColor)
        secondStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icReset.image,
                                                            text: L10n.galleryFormatResetting,
                                                            textColor: ColorName.disabledTextColor)
        thirdStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icCreate.image,
                                                           text: L10n.galleryFormatCreatingPartition,
                                                           textColor: ColorName.disabledTextColor)
    }

    /// Updates UI according to formatting state.
    ///
    /// - Parameter state: the formatting state
    func updateFormattingState(with state: StorageFormattingState) {
        switch state {
        case .unavailable(let reason):
            // Formatting is unavailable => disable interaction and update UI.
            secondaryLabel.text = reason.message
            choicesStackView.isUserInteractionEnabled = false
            choicesStackView.alphaWithEnabledState(false)
            confirmationAlert?.dismissAlert()
            confirmationAlert = nil

        case .available(let status):
            // Formatting is available => enable default UI.
            secondaryLabel.text = L10n.galleryFormatDataErased
            choicesStackView.isUserInteractionEnabled = true
            choicesStackView.alphaWithEnabledState(true)

            guard let status = status else { return }

            // Formatting process is ongoing => Update status.
            switch status.step {
            case .partitioning:
                self.firstStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icErasing.image,
                                                                        text: L10n.galleryFormatErasingPartition,
                                                                        textColor: ColorName.highlightColor)
            case .clearingData:
                self.secondStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icReset.image,
                                                                         text: L10n.galleryFormatResetting,
                                                                         textColor: ColorName.highlightColor)
            case .creatingFs:
                self.thirdStepView.model = GalleryFormatSDCardStepModel(image: Asset.Gallery.Format.icCreate.image,
                                                                        text: L10n.galleryFormatCreatingPartition,
                                                                            textColor: ColorName.highlightColor)
            }

            circleProgressView.setProgress(viewModel.displayedProgress(for: status))

            if state.isComplete {
                // Stop listening to updates.
                cancellables.removeAll()

                // Slightly delay view closing in order to ensure 100 % completion remains visible
                // for a reasonable time.
                DispatchQueue.main.asyncAfter(deadline: .now() + Style.transitionAnimationDuration) {
                    self.close(message: L10n.galleryFormatComplete)
                }
            }

        case .unknown:
            break
        }
    }

    /// Shows a format confirmation popup.
    ///
    /// - Parameter type: the selected formatting type
    func showConfirmationPopup(type: FormattingType) {
        let formatAction = AlertAction(title: L10n.commonFormat,
                                       style: .destructive,
                                       isActionDelayedAfterDismissal: false,
                                       actionHandler: { [weak self] in
            self?.startFormatting(type)
        })
        let cancelAction = AlertAction(title: L10n.cancel,
                                       style: .default2,
                                       actionHandler: {})
        confirmationAlert = showAlert(title: L10n.galleryFormatSdCard,
                                      message: L10n.galleryFormatSdCardConfirmationDesc,
                                      cancelAction: cancelAction,
                                      validateAction: formatAction)
    }

    /// Updates close modal state.
    ///
    /// - Parameter canClose: whether the popup can be closed
    func updateCloseModalState(canClose: Bool) {
        closeButton.isEnabled = canClose
        backgroundButton.isEnabled = canClose
    }

    /// Called when the formatting needs to start.
    ///
    /// - Parameters:
    ///    - type: formatting type
    func startFormatting(_ type: FormattingType) {
        // Formatting will start, disable modal closing ability as formatting cannot be interrupted.
        updateCloseModalState(canClose: false)

        choicesStackView.isHidden = true
        formattingView.isHidden = false
        viewModel.selectedFormattingType = type
        formattingImageView.image = type == .quick ? Asset.Common.Icons.icSdCardFormatQuick.image : Asset.Common.Icons.icSdCardFormatFull.image
        primaryLabel.text = L10n.galleryFormatFormatting
        secondaryLabel.text = nil

        viewModel.format()
    }

    /// Closes screen with optional toast message.
    ///
    /// - Parameters:
    ///    - message: the toast message to display (if any)
    ///    - duration: the toast message duration (relevant only if `message` is non-`nil`)
    func close(message: String? = nil, duration: TimeInterval = Style.longAnimationDuration) {
        view.backgroundColor = .clear
        viewModel.close(message: message, duration: duration)
    }
}
