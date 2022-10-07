//    Copyright (C) 2021 Parrot Drones SAS
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
import Reusable

class FlightExecutionDetailsStatusCell: MainTableViewCell, NibReusable {
    @IBOutlet weak var statusTitleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var uploadingStack: UIStackView!
    @IBOutlet weak var uploadingPhotosCountLabel: UILabel!
    @IBOutlet weak var uploadingPhotoIcon: UIImageView!
    @IBOutlet weak var uploadingExtraIcon: UIImageView!
    @IBOutlet weak var uploadingProgressLabel: UILabel!

    @IBOutlet weak var uploadPausedStack: UIStackView!
    @IBOutlet weak var uploadPausedLabel: UILabel!
    @IBOutlet weak var uploadPausedProgressLabel: UILabel!

    @IBOutlet weak var freemiumDescription: UILabel!

    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var actionButtonProgressView: UIView!
    @IBOutlet weak var actionButtonIcon: UIImageView!
    @IBOutlet weak var actionButtonTitle: UILabel!
    @IBOutlet weak var actionButtonProgressWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButtonHeight: NSLayoutConstraint!

    private var cancellables = Set<AnyCancellable>()
    private var tapGestureSubscriber: AnyCancellable?
    private var viewModel: FlightExecutionDetailsStatusCellModel?

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.forEach { $0.cancel() }
        cancellables = []
        tapGestureSubscriber?.cancel()
    }

    func setupUI() {
        statusTitleLabel.makeUp(with: .caps, color: .disabledTextColor)
        statusTitleLabel.text = L10n.flightPlanDetailsStatusTitle.uppercased()
        statusLabel.makeUp(with: .current, color: .defaultTextColor)
        statusLabel.isHidden = true

        uploadingPhotosCountLabel.makeUp(with: .largeMedium, and: .defaultTextColor)
        uploadingProgressLabel.makeUp(with: .small, and: .defaultTextColor)
        uploadingExtraIcon.tintColor = ColorName.blueDodger.color
        uploadingStack.isHidden = true

        uploadPausedLabel.makeUp(with: .small, and: .warningColor)
        uploadPausedProgressLabel.makeUp(with: .small, and: .greyShark)
        uploadPausedProgressLabel.isHidden = true
        uploadPausedStack.isHidden = true

        freemiumDescription.makeUp(with: .small, and: .warningColor)
        freemiumDescription.isHidden = true

        actionButton.applyCornerRadius(Style.largeCornerRadius)
        actionButtonProgressView.isHidden = true
        actionButtonTitle.makeUp(with: .current, color: .defaultTextColor)
        actionButtonProgressWidthConstraint.constant = 0
        actionButton.isHidden = true
        actionButtonHeight.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
    }
}

extension FlightExecutionDetailsStatusCell {

    // Populate the cell.
    func fill(with viewModel: FlightExecutionDetailsStatusCellModel) {
        self.viewModel = viewModel
        hideAll()
        configure(with: viewModel)
    }

    private func configure(with viewModel: FlightExecutionDetailsStatusCellModel) {
        cancellables.forEach { $0.cancel() }
        cancellables = []

        // FlightPlan Status
        Publishers.CombineLatest(viewModel.$statusText, viewModel.$statusTextColor)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .sink { [weak self] in
                guard let self = self else { return }
                if let statusText = $0,
                   let statusTextColor = $1 {
                    self.updateStatus(text: statusText,
                                      textColor: statusTextColor)
                } else {
                    self.hideStatus()
                }
            }
            .store(in: &cancellables)

        // Uploading Photo State.
        Publishers.CombineLatest(viewModel.$uploadingPhotosCount, viewModel.$uploadingProgressText)
            .sink { [weak self] in
                guard let self = self else { return }
                if let uploadingPhotosCount = $0,
                   let uploadingProgressText = $1 {
                    self.showUploadingInfo(photoCount: uploadingPhotosCount,
                                           extraIcon: viewModel.uploadingExtraIcon,
                                           extraIconColor: viewModel.uploadingExtraIconColor,
                                           progressText: uploadingProgressText)
                } else {
                    self.hideUploadingInfo()
                }
            }
            .store(in: &cancellables)

        // Listen uploading bytes text changes.
        viewModel.$uploadingProgressText
            .compactMap { $0 }
            .sink { [weak self] text in
                self?.updateUploadingInfo(progressText: text)
            }.store(in: &cancellables)

        // Upload paused state.
        viewModel.$uploadPausedText
            .sink { [weak self] uploadPausedText in
                guard let self = self else { return }
                if let uploadPausedText = uploadPausedText {
                    self.showUploadPausedInfo(text: uploadPausedText,
                                              textColor: viewModel.uploadPausedTextColor,
                                              progressText: viewModel.uploadPausedProgressText)
                } else {
                    self.hideUploadPausedInfo()
                }
            }
            .store(in: &cancellables)

        // Freemium account info.
        if let freemiumText = viewModel.freemiumText {
            showFreemiumInfo(text: freemiumText)
        } else {
            hideFreemiumInfo()
        }

        // Action Button.
        Publishers.CombineLatest4(viewModel.$actionButtonIcon,
                                  viewModel.$actionButtonText,
                                  viewModel.$actionButtonTextColor,
                                  viewModel.$actionButtonColor)
            .sink { [weak self] (icon, text, textColor, buttonColor) in
                guard let self = self else { return }
                if let actionButtonText = text,
                   let actionButtonTextColor = textColor,
                   let actionButtonColor = buttonColor {
                    self.showActionButton(icon: viewModel.actionButtonIcon,
                                          text: actionButtonText,
                                          textColor: actionButtonTextColor,
                                          backgroundColor: actionButtonColor,
                                          progress: viewModel.actionButtonProgress,
                                          progressColor: viewModel.actionButtonProgressColor,
                                          action: viewModel.actionButtonAction)
                } else {
                    self.hideActionButton()
                }
            }
            .store(in: &cancellables)

        // Listen to action button isEnabled state.
        viewModel.$isActionButtonEnabled
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self = self else { return }
                // Update action button opacity according to its isEnabled state.
                // Tap event is handled in tapGestureSubscriber.
                self.actionButton.alphaWithEnabledState(isEnabled ?? true)
            }
            .store(in: &cancellables)

        viewModel.$actionButtonProgress
            .compactMap { $0 }
            .sink { [weak self] progress in
                guard let self = self else { return }
                self.hideUploadPausedInfo()
                self.updateActionButtonProgress(to: progress,
                                                progressColor: viewModel.actionButtonProgressColor)
            }
            .store(in: &cancellables)
    }
}

// MARK: - UI Setting
extension FlightExecutionDetailsStatusCell {

    /// Hide all fields.
    func hideAll() {
        hideStatus()
        hideUploadingInfo()
        hideUploadPausedInfo()
        hideActionButton()
        hideFreemiumInfo()
    }

    /// Update the top-right status text.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - textColor: The text color.
    func updateStatus(text: String,
                      textColor: UIColor) {
        statusLabel.text = text
        statusLabel.textColor = textColor
        statusLabel.isHidden = false
    }

    /// Hide the top-right status text.
    func hideStatus() {
        statusLabel.isHidden = true
    }

    /// Show the  uploading indicator.
    ///
    /// Display the uploading  status with number of photos to upload and current uploaded bytes.
    ///
    /// - Parameters:
    ///   - photoCount: The number of photo to upload.
    ///   - extraIcon: The extra icon.
    ///   - extraIconColor: The extra icon color.
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func showUploadingInfo(photoCount: Int,
                           extraIcon: UIImage? = nil,
                           extraIconColor: Color? = ColorName.blueDodger.color,
                           progressText: String) {
        uploadingPhotosCountLabel.text = "\(photoCount)"
        uploadingProgressLabel.text = progressText
        uploadingExtraIcon.image =  extraIcon?.withRenderingMode(.alwaysTemplate)
        uploadingExtraIcon.tintColor = extraIconColor
        uploadingExtraIcon.isHidden = extraIcon == nil
        uploadingStack.isHidden = false
    }

    /// Update the uploading text.
    ///
    /// - Parameters:
    ///   - photoCount: The number of photo to upload.
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func updateUploadingInfo(progressText: String) {
        uploadingProgressLabel.text = progressText
    }

    /// Hide the uploading indicator.
    func hideUploadingInfo() {
        uploadingStack.isHidden = true
        actionButtonProgressView.backgroundColor = .clear
    }

    /// Show the state when upload is paused.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - textColor: The text color.
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func showUploadPausedInfo(text: String,
                              textColor: Color?,
                              progressText: String?) {
        uploadPausedLabel.text = text
        uploadPausedLabel.textColor = textColor != nil ? textColor : ColorName.warningColor.color
        uploadPausedProgressLabel.text = progressText
        uploadPausedProgressLabel.isHidden = progressText == nil
        uploadPausedStack.isHidden = false
    }

    /// Hide the  upload  paused indicator.
    func hideUploadPausedInfo() {
        uploadPausedStack.isHidden = true
    }

    /// Show the Freemium info.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - textColor: The text color.
    func showFreemiumInfo(text: String) {
        freemiumDescription.text = text
        freemiumDescription.isHidden = false
    }

    /// Hide the upload  paused indicator.
    func hideFreemiumInfo() {
        freemiumDescription.isHidden = true
    }

    /// Update the action button's progress indicator.
    ///
    /// - Parameters:
    ///   - progress: The button progress indicator - between 0 and 1.
    func updateActionButtonProgress(to progress: Double, progressColor: UIColor?) {
        actionButtonProgressView.isHidden = false
        if let prgColor = progressColor {
            actionButtonProgressView.backgroundColor = prgColor
        }
        actionButtonProgressWidthConstraint.constant = actionButton.frame.width * CGFloat(progress)
    }

    /// Show the action button.
    ///
    /// - Parameters:
    ///   - icon: the button's icon
    ///   - text: the button's text
    ///   - textColor: the button text color
    ///   - backgroundColor: the button  color
    ///   - progress (optional): the button progress indicator - between 0 and 1
    ///   - progressColor (optional): the button progress indicator color
    ///   - action: callback called when button tapped
    func showActionButton(icon: UIImage?,
                          text: String,
                          textColor: UIColor,
                          backgroundColor: UIColor,
                          progress: Double? = nil,
                          progressColor: UIColor? = nil,
                          action: ((Coordinator?) -> Void)? = nil) {
        actionButtonIcon.image = icon
        actionButtonIcon.isHidden = icon == nil
        actionButtonTitle.text = text
        actionButtonTitle.textColor = textColor
        actionButton.backgroundColor = backgroundColor
        if let progress = progress, let progressColor = progressColor {
            hideUploadPausedInfo()
            updateActionButtonProgress(to: progress, progressColor: progressColor)
        }
        actionButton.isHidden = false
        if let action = action {
            tapGestureSubscriber = actionButton.tapGesturePublisher
                .sink { [weak self] _ in
                    guard let self = self, self.viewModel?.isActionButtonEnabled ?? true else { return }
                    action(self.viewModel?.coordinator)
                }
        }
    }

    /// Hide the action button.
    func hideActionButton() {
        actionButton.isHidden = true
        actionButtonProgressView.isHidden = true
        tapGestureSubscriber?.cancel()
    }
}
