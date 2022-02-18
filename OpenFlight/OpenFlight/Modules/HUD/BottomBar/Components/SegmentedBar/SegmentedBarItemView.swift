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

import Reusable

/// Custom item view embedded in a `SegmentedBarView` that displays title and image.
final class SegmentedBarItemView: UIControl, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var unavailableLabel: UILabel!
    @IBOutlet private weak var imageViewContainer: UIView!
    @IBOutlet private var viewsToDisable: [UIView]!
    @IBOutlet private weak var stackView: UIStackView!

    // MARK: - Internal Properties
    var model: BarButtonState! {
        didSet {
            fill(with: model)
        }
    }

    /// Stack view orientation.
    var orientation: NSLayoutConstraint.Axis = .vertical {
        didSet {
            stackView.axis = orientation
            stackView.spacing = orientation == .vertical ? 8 : 12
        }
    }

    // MARK: - Private Properties
    private var isControlSelected: Bool = false

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    // MARK: - Override Funcs
    override var isEnabled: Bool {
        didSet {
            viewsToDisable.forEach { $0.alphaWithEnabledState(isEnabled) }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateBackgroundColor()
    }
}

// MARK: - Actions
private extension SegmentedBarItemView {
    /// Called when user taps item view.
    @IBAction func onTap(_ sender: Any) {
        if let logItem = model.mode?.logKey {
            LogEvent.log(.button(item: logItem,
                                 value: model.mode?.key ?? ""))
        }
        if model.isSelected.value {
            // Special case when item is already currently selected.
            model.isSelected.set(false)
            model.isSelected.set(true)
        } else {
            model.isSelected.set(true)
        }
    }
}

// MARK: - Private Funcs
private extension SegmentedBarItemView {
    func commonInit() {
        loadNibContent()
        imageView.tintColor = .white
    }

    /// Fills the UI elements of the view with given model.
    ///
    /// - Parameters:
    ///    - viewModel: model representing the contents
    func fill(with viewModel: BarButtonState) {
        if let key = viewModel.mode?.key,
           let unavailableReason = viewModel.unavailableReason[key] {
            unavailableLabel.isHidden = viewModel.enabled
            unavailableLabel.text = unavailableReason
        } else {
            unavailableLabel.isHidden = true
        }

        isEnabled = viewModel.enabled
        isControlSelected = viewModel.isSelected.value

        // specific display according to image
        updateIcon()

        // specific display according to label
        updateLabel()

        // specific display according to background
        updateBackgroundColor()

        layoutIfNeeded()
    }

    func updateIcon() {
        let isSelected = model.isSelected.value
        let hasImage = model.image != nil
        imageView.isHidden = !hasImage
        imageViewContainer.isHidden = !hasImage
        imageView.image = model?.image
        imageView.tintColor = isSelected ? .white : ColorName.defaultTextColor.color
    }

    func updateLabel() {
        let isSelected = model.isSelected.value
        label.text = model.subtext
        label.isHidden = model.subtext?.isEmpty ?? true
        let textColor = isSelected ? ColorName.white : ColorName.defaultTextColor
        label.makeUp(with: .current, color: textColor)
    }

    /// Updates bar item background.
    func updateBackgroundColor() {
        let isSelected = model.isSelected.value
        backgroundColor = isSelected ? ColorName.highlightColor.color : .clear
        if isSelected {
            applyCornerRadius(Style.largeCornerRadius)
        }
    }
}
