//
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
import Combine
import Reusable

class FlightExecutionDetailsStatusCell: UITableViewCell, NibReusable {
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

    @IBOutlet weak var fremiumDesription: UILabel!

    @IBOutlet weak var actionButton: UIView!
    @IBOutlet weak var actionButtonProgressView: UIView!
    @IBOutlet weak var actionButtonTitle: UILabel!
    @IBOutlet weak var actionButtonProgressWidthConstraint: NSLayoutConstraint!

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
        tapGestureSubscriber?.cancel()
        hideAll()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func setupUI() {
        statusTitleLabel.text = "Status" // TODO: Localize
        statusTitleLabel.makeUp(with: .large, and: .defaultTextColor)
        statusLabel.makeUp(with: .large, and: .defaultTextColor)
        statusLabel.isHidden = true

        uploadingPhotosCountLabel.makeUp(with: .largeMedium, and: .defaultTextColor)
        uploadingProgressLabel.makeUp(with: .small, and: .defaultTextColor)
        uploadingExtraIcon.tintColor = ColorName.blueDodger.color
        uploadingStack.isHidden = true

        uploadPausedLabel.makeUp(with: .small, and: .orangePeel)
        uploadPausedProgressLabel.makeUp(with: .small, and: .greyShark)
        uploadPausedProgressLabel.isHidden = true
        uploadPausedStack.isHidden = true

        fremiumDesription.makeUp(with: .small, and: .warningColor)
        fremiumDesription.isHidden = true

        actionButton.applyCornerRadius(Style.mediumCornerRadius)
        actionButtonProgressView.isHidden = true
        actionButtonTitle.makeUp(with: .large, and: .defaultTextColor)
        actionButtonProgressWidthConstraint.constant = 0
        actionButton.isHidden = true
    }

    // MARK: - Constants
    enum Constants {
        static let progressAnimationDuration = 0.5
    }

}

extension FlightExecutionDetailsStatusCell {

    // Populate the cell.
    func fill(with viewModel: FlightExecutionDetailsStatusCellModel) {
        self.viewModel = viewModel
        initCell(with: viewModel)
    }

    func initCell(with viewModel: FlightExecutionDetailsStatusCellModel) {
        cancellables.forEach { $0.cancel() }
        hideAll()
        // FlightPlan Status
        if let statusText = viewModel.statusText,
           let statusTextColor = viewModel.statusTextColor {
            updateStatus(text: statusText,
                         textColor: statusTextColor)
        } else {
            hideStatus()
        }

        // Uploading Photo State.
        if let uploadingPhotosCount = viewModel.uploadingPhotosCount,
           let uploadingProgressText = viewModel.uploadingProgressText {
            showUploadingInfo(photoCount: uploadingPhotosCount,
                              extraIcon: viewModel.uploadingExtraIcon,
                              progressText: uploadingProgressText)

            // Listen uploading bytes text changes.
            viewModel.$uploadingProgressText
                .sink { [weak self] text in
                    self?.updateUploadingInfo(progressText: text ?? "")
                }
                .store(in: &cancellables)

        } else {
            hideUploadingInfo()
        }

        // Upload paused state.
        if let uploadPausedText = viewModel.uploadPausedText {
            showUploadPausedInfo(text: uploadPausedText,
                                 progressText: viewModel.uploadPausedProgressText)
        } else {
            hideUploadPausedInfo()
        }

        // Freemium account info.
        if let freemiumText = viewModel.freemiumText {
            showFreemiumInfo(text: freemiumText)
        } else {
            hideFreemiumInfo()
        }

        // Action Button.
        if let actionButtonText = viewModel.actionButtonText,
           let actionButtonTextColor = viewModel.actionButtonTextColor,
           let actionButtonColor = viewModel.actionButtonColor {

            showActionButton(text: actionButtonText,
                             textColor: actionButtonTextColor,
                             backgroundColor: actionButtonColor,
                             progress: viewModel.actionButtonProgress,
                             progressColor: viewModel.actionButtonProgressColor,
                             action: viewModel.actionButtonAction)

            // If needed, listen progress changes
            if viewModel.actionButtonProgress != nil {
                viewModel.$actionButtonProgress
                    .sink { [weak self] progress in
                        self?.updateActionButtonProgress(to: progress ?? 0)
                    }
                    .store(in: &cancellables)
            }
        } else {
            hideActionButton()
        }
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
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func showUploadingInfo(photoCount: Int,
                           extraIcon: UIImage? = nil,
                           progressText: String) {
        uploadingPhotosCountLabel.text = "\(photoCount)"
        uploadingProgressLabel.text = progressText
        uploadingExtraIcon.image =  extraIcon?.withRenderingMode(.alwaysTemplate)
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
    }

    /// Show the state when upload is paused.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func showUploadPausedInfo(text: String,
                              progressText: String?) {
        uploadPausedLabel.text = text
        uploadPausedProgressLabel.text = progressText
        uploadPausedProgressLabel.isHidden = progressText == nil
        uploadPausedStack.isHidden = false
   }

    /// Hide the  upload  paused indicator.
    func hideUploadPausedInfo() {
        uploadPausedStack.isHidden = true
    }

    /// Update the upload paused text.
    ///
    /// - Parameters:
    ///   - photoCount: The number of photo to upload.
    ///   - progressText: The text representing the number of bytes uploaded of total number of bytes to upload.
    func updateUploadPauseInfo(progressText: String) {
        uploadPausedProgressLabel.text = progressText
    }

    /// Show the Freemium info.
    ///
    /// - Parameters:
    ///   - text: The text to display.
    ///   - textColor: The text color.
    func showFreemiumInfo(text: String) {
        fremiumDesription.text = text
        fremiumDesription.isHidden = false
    }

    /// Hide the upload  paused indicator.
    func hideFreemiumInfo() {
        fremiumDesription.isHidden = true
    }

    /// Update the action button's progress indicator.
    ///
    /// - Parameters:
    ///   - progress: The button progress indicator - between 0 and 1.
    func updateActionButtonProgress(to progress: Double) {
        DispatchQueue.main.async { [unowned self] in
            actionButtonProgressWidthConstraint.constant = actionButton.frame.width * CGFloat(progress)
        }
    }

    /// Show the action button.
    ///
    /// - Parameters:
    ///   - text: The button text.
    ///   - textColor: The button text color.
    ///   - backgroundColor: The button  color.
    ///   - progress (optional): The button progress indicator - between 0 and 1.
    ///   - progressColor (optional): The button progress indicator color.
    ///   - action: callback called when button tapped.
    func showActionButton(text: String,
                          textColor: UIColor,
                          backgroundColor: UIColor,
                          progress: Double? = nil,
                          progressColor: UIColor? = nil,
                          action: ((Coordinator?) -> Void)? = nil) {
        actionButtonTitle.text = text
        actionButtonTitle.textColor = textColor
        actionButton.backgroundColor = backgroundColor
        if let progress = progress, let progressColor = progressColor {
            updateActionButtonProgress(to: progress)
            actionButtonProgressView.backgroundColor = progressColor
        }
        actionButtonProgressView.isHidden = progress == nil
        actionButton.isHidden = false
        if let action = action {
            tapGestureSubscriber = actionButton.tapGesturePublisher
                .sink { [weak self] _ in
                    action(self?.viewModel?.coordinator)
                }
        }
    }

    /// Hide the action button.
    func hideActionButton() {
        actionButton.isHidden = true
        tapGestureSubscriber?.cancel()
   }

 }
