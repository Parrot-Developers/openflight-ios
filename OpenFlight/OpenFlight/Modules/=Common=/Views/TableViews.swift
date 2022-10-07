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

/// A side panel tableView container adjusting its magins according to `Layout.mainPadding`.
/// Width constraint can be disabled view `isSidePanel` property.
public class SidePanelTableView: UITableView {
    /// The tableView margin borders that are enabled. Disabled borders have a margin set to 0.
    /// Horizontal margins are supposed to be handled via tableView cells as their width is equal
    /// to their superview's.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.top, .bottom] {
        didSet { updateMargins() }
    }
    /// The tableView borders that are connected to the device's screen. Used to correctly handle safe area offsets if needed.
    var screenBorders: [NSLayoutConstraint.Attribute] = [] {
        didSet { updateWidth() }
    }
    /// If tableView is a side panel. Corresponding width constraint will be active if `true`, inactive otherwise.
    var isSidePanel: Bool = true {
        didSet { updateWidth() }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Private
    /// Tableview's side panel width constraint.
    private var widthAnchorConstraint: NSLayoutConstraint?

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = false
        updateMargins()
        updateWidth()
    }

    private func updateMargins() {
        // Only .vertical values of `screenBorders` will affect margins, as .horizontal margins are supposed
        // to be handled by tableView's cells.
        let margins = Layout.fileCollectionViewContentInset(isRegularSizeClass, screenBorders: screenBorders)
        layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                              left: 0,
                              bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                              right: 0)
    }

    private func updateWidth() {
        if let widthAnchorConstraint = widthAnchorConstraint {
            removeConstraint(widthAnchorConstraint)
        }
        // Only .left value of `screenBorder` can affect width.
        let widthConstant = screenBorders.contains(.left)
        ? Layout.leftSidePanelWidth(isRegularSizeClass)
        : Layout.sidePanelWidth(isRegularSizeClass)
        widthAnchorConstraint = widthAnchor.constraint(equalToConstant: widthConstant)
        widthAnchorConstraint?.isActive = isSidePanel
    }
}

/// A general-purpose tableViewCell container adjusting its margins according to `Layout.mainSpacing` and `Layout.mainPadding`.
public class MainTableViewCell: UITableViewCell {
    /// The cell margin borders that are enabled. Disabled borders have a margin set to 0.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .right, .bottom] {
        didSet { updateMargins() }
    }
    /// The cell borders that are connected to the device's screen. Used to correctly handle safe area offsets if needed.
    var screenBorders: [NSLayoutConstraint.Attribute] = [] {
        didSet { updateMargins() }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = false
        updateMargins()
    }

    private func updateMargins() {
        let margins = Layout.tableViewCellContentInset(isRegularSizeClass,
                                                       screenBorders: screenBorders)
        contentView.layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                                          left: enabledMargins.contains(.left) ? margins.left : 0,
                                          bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                                          right: enabledMargins.contains(.right) ? margins.right : 0)
    }
}

/// A general-purpose tableViewCell container adjusting its margins according to `Layout.mainSpacing` and `Layout.mainPadding`.
public class SettingsTableViewCell: MainTableViewCell {
    private func updateMargins() {
        let margins = Layout.tableViewCellSettingsContentInset(isRegularSizeClass,
                                                               screenBorders: screenBorders)
        contentView.layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                                          left: enabledMargins.contains(.left) ? margins.left : 0,
                                          bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                                          right: enabledMargins.contains(.right) ? margins.right : 0)
    }
}

public enum SidePanelSettingType {
    case slider
    case textSegments               // SegmentedControls without picto
    case textAndIconSegments        // SegmentedControls with picto
    case textAndIconSegmentsLarge   // SegmentedControls with picto and more than 3 segments

    /// Returns the setting height according to its type.
    ///
    /// - Parameter isRegularSizeClass: whether the device has a regular size class
    /// - Returns: the height of the setting
    func height(_ isRegularSizeClass: Bool) -> CGFloat {
        self == .textSegments
        ? Layout.sidePanelSettingTextSegmentsHeight(isRegularSizeClass)
        : Layout.sidePanelSettingShortPictoSegmentsHeight(isRegularSizeClass)
    }
}

/// A tableViewCell container adjusting its margins according to Side Panel Setting.
public class SidePanelSettingTableViewCell: UITableViewCell {
    /// The cell margin borders that are enabled. Disabled borders have a margin set to 0.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .right, .top, .bottom] {
        didSet { updateMargins() }
    }

    /// The setting type.
    var cellSettingType: SidePanelSettingType = .textSegments

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = false
        updateMargins()
    }

    private func updateMargins() {
        let margins = Layout.sidePanelSettingTableViewCellContentInset(isRegularSizeClass)
        contentView.layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                                          left: enabledMargins.contains(.left) ? margins.left : 0,
                                          bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                                          right: enabledMargins.contains(.right) ? margins.right : 0)
    }
}

/// A general-purpose table view cell container view adjusting its margins according to `Layout.mainSpacing`.
public class TableViewCellContainerView: UIView {
    /// The cell margin borders that are enabled. Disabled borders have a margin set to 0.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .right, .bottom, .top] {
        didSet { updateMargins() }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = false
        updateMargins()
    }

    private func updateMargins() {
        let margins = Layout.tableViewCellContainerInset(isRegularSizeClass)
        layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                              left: enabledMargins.contains(.left) ? margins.left : 0,
                              bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                              right: enabledMargins.contains(.right) ? margins.right : 0)
    }
}

/// A general-purpose table view cell container stack view adjusting its margins according to `Layout.mainSpacing`.
public class TableViewCellContainerStackView: UIStackView {
    /// The cell margin borders that are enabled. Disabled borders have a margin set to 0.
    var enabledMargins: [NSLayoutConstraint.Attribute] = [.left, .right, .bottom, .top] {
        didSet { updateMargins() }
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setupView()
    }

    // MARK: - Layout Configuration
    func setupView() {
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = false
        isLayoutMarginsRelativeArrangement = true
        updateMargins()
    }

    private func updateMargins() {
        let margins = Layout.tableViewCellContainerInset(isRegularSizeClass)
        layoutMargins = .init(top: enabledMargins.contains(.top) ? margins.top : 0,
                              left: enabledMargins.contains(.left) ? margins.left : 0,
                              bottom: enabledMargins.contains(.bottom) ? margins.bottom : 0,
                              right: enabledMargins.contains(.right) ? margins.right : 0)
    }
}
