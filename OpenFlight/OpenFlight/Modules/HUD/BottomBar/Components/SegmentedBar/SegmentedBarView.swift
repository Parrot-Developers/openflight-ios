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

import Reusable

// MARK: - Protocols
protocol SegmentedBarViewDelegate: AnyObject {
    /// Called when an item is selected within bar without autoclosing.
    func didSelectWithoutAutoClosing(mode: BarItemMode)
}

// MARK: - Private Enums
private enum Constants {
    static let selectionDelay: TimeInterval = 0.2
    static let fadeAnimationDuration: TimeInterval = 0.1
}

/// Custom view that displays severals item of type `SegmentedBarItemView` in a bar.

final class SegmentedBarView<T: BarButtonState>: UIView, NibOwnerLoadable, NibLoadable, BarItemModeDisplayer {

    // MARK: - Outlets
    @IBOutlet private weak var containerStackView: UIStackView!
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var moreArrowView: UIControl!
    @IBOutlet private weak var lessArrowView: UIControl!

    // MARK: - Internal Properties
    static var nib: UINib {
        return UINib(nibName: "SegmentedBarView", bundle: Bundle.currentBundle(for: self))
    }

    var modeKey: String? {
        return viewModel?.state.value.mode?.key
    }

    weak var viewModel: BarButtonViewModel<T>? {
        didSet {
            updateModels()
        }
    }

    var isHighlighted: Bool = false {
        didSet {
            displayItems()
        }
    }

    var isEnabled: Bool = true {
        didSet {
            displayItems()
        }
    }

    /// Max items displayed at same time on segmented bar.
    /// Additionnal items are accessible via navigation arrows.
    var maxItems: Int = 5

    /// Orientation of the items.
    /// - Note: Should be set before viewModel.
    var itemsOrientation: NSLayoutConstraint.Axis = .vertical
    weak var delegate: SegmentedBarViewDelegate?

    // MARK: - Private Properties
    private var startItemIndex: Int = 0

    private var models = [BarButtonState]() {
        didSet {
            // Reset pagination if needed.
            if models.count < startItemIndex {
                startItemIndex = 0
            }
        }
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    func commonInit() {
        self.loadNibContent()
        updateModels()
    }

    // MARK: - Actions
    @IBAction private func seeMoreItems() {
        startItemIndex += maxItems
        displayItems()
    }

    @IBAction private func seeLessItems() {
        startItemIndex -= maxItems
        displayItems()
    }

    // MARK: - Internal Funcs
    /// Generate models for items `SegmentedBarItemView` from viewModel modes.
    func updateModels() {
        guard let currentMode = viewModel?.state.value.mode else { return }
        let supportedValues: [BarItemMode]
        guard let unavailableReason = viewModel?.state.value.unavailableReason else { return }

        if viewModel?.state.value.showUnsupportedModes == true {
            supportedValues = type(of: currentMode).allValues
        } else {
            supportedValues = viewModel?.state.value.supportedModes ?? type(of: currentMode).allValues
        }

        models = supportedValues.map { mode in
            let isEnabled = viewModel?.state.value.supportedModes?.contains(where: { mode.key == $0.key }) ?? mode.isAvailable
            let itemState = CameraBarButtonState(mode: mode,
                                                 enabled: isEnabled,
                                                 isSelected: Observable(currentMode.key == mode.key),
                                                 unavailableReason: unavailableReason)
            itemState.isSelected.valueChanged = { [weak self] isSelected in
                if isSelected, let mode = itemState.mode {
                    if mode.autoClose {
                        self?.viewModel?.update(mode: mode)
                        if mode.subModes?.isEmpty == false {
                            self?.updateSubModeModels()
                            self?.displayItems(animated: true)
                            // Reset pagination.
                            self?.startItemIndex = 0
                        } else {
                            self?.stackView?.isUserInteractionEnabled = false // Prevents double tap issues.
                            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.selectionDelay) {
                                self?.viewModel?.toggleSelectionState()
                                self?.stackView?.isUserInteractionEnabled = true // Prevents double tap issues.
                            }
                            self?.updateModels()
                        }
                    } else {
                        self?.delegate?.didSelectWithoutAutoClosing(mode: mode)
                    }
                }
            }
            return itemState
        }
        displayItems()
    }
}

// MARK: - Private Funcs
private extension SegmentedBarView {

    /// Generate models for items `SegmentedBarItemView` from viewModel subModes.
    func updateSubModeModels() {
        guard let subMode = viewModel?.state.value.subMode else { return }
        guard let unavailableReason = viewModel?.state.value.unavailableReason else { return }
        models = type(of: subMode).allValues.map {
            let itemState = CameraBarButtonState(mode: $0,
                                                 enabled: $0.isAvailable,
                                                 isSelected: Observable(subMode.key == $0.key),
                                                 unavailableReason: unavailableReason)
            itemState.isSelected.valueChanged = { [weak self] isSelected in
                if isSelected, let subMode = itemState.mode as? BarItemSubMode {
                    self?.stackView?.isUserInteractionEnabled = false // Prevents double tap issues.
                    self?.viewModel?.update(subMode: subMode)
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.selectionDelay) {
                        self?.viewModel?.toggleSelectionState()
                        self?.stackView?.isUserInteractionEnabled = true // Prevents double tap issues.
                    }
                    self?.updateSubModeModels()
                    self?.displayItems()
                }
            }
            return itemState
        }
    }

    /// Displays bar items `SegmentedBarItemView` into a stackView.
    ///
    /// - Parameters:
    ///    - animated: displays items with animation when set to true
    func displayItems(animated: Bool) {

        guard animated else {
            displayItems()
            return
        }

        // Fade out
        UIView.animate(withDuration: Constants.fadeAnimationDuration, animations: {
            self.stackView.alpha = 0.0
        }, completion: { _ in
            self.displayItems()
            // Fade in
            UIView.animate(withDuration: Constants.fadeAnimationDuration, animations: {
                self.stackView.alpha = 1.0
            })
        })
    }

    /// Displays bar items `SegmentedBarItemView` into a stackView.
    func displayItems() {
        guard !models.isEmpty else { return }

        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let endItemIndex = startItemIndex + maxItems - 1
        models[startItemIndex...min(endItemIndex, models.count - 1)]
            .map {
                let itemView = SegmentedBarItemView(frame: .zero)
                itemView.model = $0
                itemView.orientation = itemsOrientation
                return itemView
            }
            .forEach { stackView.addArrangedSubview($0) }

        moreArrowView.isHidden = endItemIndex >= models.count - 1
        lessArrowView.isHidden = startItemIndex == 0
        isUserInteractionEnabled = isEnabled
        alpha = isEnabled ? 1 : 0.5
        layoutIfNeeded()
    }
}
