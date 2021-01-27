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
import Reusable

// MARK: - Protocols
/// Protocol for live streaming view updating.
protocol LiveStreamingTableViewCellDelegate: class {
    /// Update panel top constraint.
    ///
    /// - Parameters:
    ///     - isKeyboardHidden: tells if the keyboard is hidden
    func updateTopConstraint(isKeyboardHidden: Bool)

    /// Called when user deletes an url which is not registered.
    func deleteNotRegisteredUrl()
}

/// Cell used to manage live streaming url.

final class LiveStreamingTableViewCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var labelTextField: UITextField!
    @IBOutlet private weak var labelView: UIView!
    @IBOutlet private weak var confirmDeleteStackView: UIStackView!
    @IBOutlet private weak var urlTextField: UITextField!
    @IBOutlet private weak var urlView: UIView!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var confirmDeleteButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var encryptedImageView: UIImageView!
    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: LiveStreamingTableViewCellDelegate?

    // MARK: - Private Properties
    private var viewModel: LiveStreamingCellViewModel?
    private var isDeleteButtonSelected: Bool = false

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
        initViewModel()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetView()
    }

    // MARK: - Internal Funcs
    /// Flll the cell.
    ///
    /// - Parameters:
    ///     - state: current live streaming state
    func fill(state: UrlLiveStreaming?) {
        labelTextField.text = state?.label
        urlTextField.text = state?.url
        enabledButtonInteraction()
    }
}

// MARK: - Actions
private extension LiveStreamingTableViewCell {
    @IBAction func connectButtonTouchedUpInside(_ sender: Any) {
        viewModel?.connect(label: labelTextField.text,
                           url: urlTextField.text,
                           completion: { _ in
                            // TODO: To be continued with stream connection state.
        })
    }

    @IBAction func deleteButtonTouchedUpInside(_ sender: Any) {
        if isDeleteButtonSelected {
            deleteUrl()
        }
        isDeleteButtonSelected = !isDeleteButtonSelected
        confirmDeleteStackView.isHidden = !isDeleteButtonSelected
        connectButton.isHidden = isDeleteButtonSelected
        updateDeleteButton(isSelected: isDeleteButtonSelected)
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        confirmDeleteStackView.isHidden = true
        connectButton.isHidden = false
        isDeleteButtonSelected = false
        updateDeleteButton(isSelected: isDeleteButtonSelected)
    }

    @IBAction func confirmDeleteButtonTouchedUpInside(_ sender: Any) {
        deleteUrl()
    }
}

// MARK: - Private Funcs
private extension LiveStreamingTableViewCell {
    /// Init the view.
    func initView() {
        connectButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                         borderColor: .clear,
                                         radius: Style.largeCornerRadius)
        cancelButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                        borderColor: .clear,
                                        radius: Style.largeCornerRadius)
        confirmDeleteButton.cornerRadiusedWith(backgroundColor: ColorName.redTorch25.color,
                                               borderColor: .clear,
                                               radius: Style.largeCornerRadius)
        labelView.cornerRadiusedWith(backgroundColor: ColorName.white10.color,
                                     borderColor: .clear,
                                     radius: Style.largeCornerRadius)
        urlView.cornerRadiusedWith(backgroundColor: ColorName.white10.color,
                                   borderColor: .clear,
                                   radius: Style.largeCornerRadius)

        urlTextField.backgroundColor = .clear
        urlTextField.borderStyle = .none
        urlTextField.delegate = self
        urlTextField.placeholder = L10n.liveStreamingEnterUrl
        labelTextField.borderStyle = .none
        labelTextField.backgroundColor = .clear
        labelTextField.delegate = self

        connectButton.setTitle(L10n.liveStreamingConnect, for: .normal)
        connectButton.makeup(with: .regular, color: ColorName.white)
        confirmDeleteButton.setTitle(L10n.liveStreamingDeleteConf, for: .normal)
        confirmDeleteButton.makeup(with: .regular, color: ColorName.white)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.makeup(with: .regular, color: ColorName.white)
        updateDeleteButton(isSelected: false)

        // Manage keyboard appearance.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Reset each view in order to reuse the cell.
    func resetView() {
        labelTextField.text = nil
        urlTextField.text = nil
        connectButton.isEnabled = false
        connectButton.isHidden = false
        encryptedImageView.isHidden = true
        connectButton.setTitle(L10n.liveStreamingConnect, for: .normal)
        descriptionLabel.isHidden = true
        confirmDeleteStackView.isHidden = true
        isDeleteButtonSelected = false
        enabledButtonInteraction()
        updateDeleteButton(isSelected: false)
    }

    /// Update delete button view.
    ///
    /// - Parameters:
    ///     - isSelected: tells if the button is selected
    func updateDeleteButton(isSelected: Bool) {
        deleteButton.cornerRadiusedWith(backgroundColor: isSelected ? ColorName.redTorch25.color : .clear,
                                        borderColor: isSelected ? ColorName.redTorch.color : .clear ,
                                        radius: isSelected ? Style.largeCornerRadius : 0.0,
                                        borderWidth: isSelected ? Style.mediumBorderWidth : 0.0)
    }

    /// Init the view model for the cell.
    func initViewModel() {
        viewModel = LiveStreamingCellViewModel(stateDidUpdate: { [weak self] state in
            self?.updateView(for: state)
        })
        updateView(for: viewModel?.state.value)
    }

    /// Uodate view according to the view model.
    ///
    /// - Parameters:
    ///     - state: current state
    func updateView(for state: LiveStreamingCellState?) {
        descriptionLabel.isHidden = state?.liveStreamingConnectionState != .error
        descriptionLabel.text = state?.liveStreamingConnectionState.description
        connectButton.setTitle(state?.liveStreamingConnectionState.buttonTitle, for: .normal)
        encryptedImageView.isHidden = state?.isUrlEncrypted == false
    }

    /// Enable user interaction on button.
    func enabledButtonInteraction() {
        let isEmpty: Bool = urlTextField.text?.isEmpty == true
        connectButton.isEnabled = !isEmpty
        connectButton.setTitleColor(isEmpty ? ColorName.greenSpring20.color : ColorName.greenSpring.color,
                                    for: .normal)
    }

    /// Delete the selected Url.
    func deleteUrl() {
        viewModel?.checkRegisteredUrl(label: labelTextField.text ?? "",
                                      url: urlTextField.text ?? "",
                                      completion: { result in
                                        if result {
                                            self.viewModel?.deleteUrl(label: self.labelTextField.text,
                                                                      url: self.urlTextField.text)
                                        } else {
                                            self.delegate?.deleteNotRegisteredUrl()
                                        }
        })
        confirmDeleteStackView.isHidden = true
    }
}

// MARK: - UITextField Delegate
extension LiveStreamingTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        enabledButtonInteraction()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        enabledButtonInteraction()
    }
}

// MARK: - Keyboard Helpers
private extension LiveStreamingTableViewCell {
    /// Manages view display when keyboard is displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        // Move view upward.
        delegate?.updateTopConstraint(isKeyboardHidden: false)
    }

    /// Manages view display after keyboard is dismissed.
    @objc func keyboardWillHide(sender: NSNotification) {
        // Move view to original position.
        delegate?.updateTopConstraint(isKeyboardHidden: true)
    }
}
