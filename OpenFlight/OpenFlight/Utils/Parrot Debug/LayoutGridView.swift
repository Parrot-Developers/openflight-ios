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
import Reusable
import Combine

enum TopBarMode: Int {
    case hud, fileManager
}

enum LayoutGuideArea {
    case topBar, bottomBar, leftPanel, rightPanel
}

class LayoutGridModel {
    static let shared = LayoutGridModel()

    @Published private(set) var isShown: Bool = false
    @Published private(set) var topBarMode: TopBarMode = .hud
    @Published private(set) var areas: Set<LayoutGuideArea> = [.topBar, .bottomBar, .leftPanel, .rightPanel]
    @Published private(set) var hasCenterGuides: Bool = true

    var hasTopBarArea: Bool { areas.contains(.topBar) }
    var hasBottomBarArea: Bool { areas.contains(.bottomBar) }
    var hasLeftPanelArea: Bool { areas.contains(.leftPanel) }
    var hasRightPanelArea: Bool { areas.contains(.rightPanel) }

    func toggleVisibleState(forceIsShown: Bool = false) {
        isShown = forceIsShown ? true : isShown ? false : true
    }

    func toggle(_ area: LayoutGuideArea) {
        if areas.contains(area) {
            areas.remove(area)
        } else {
            areas.insert(area)
        }
    }

    func setTopBarMode(_ mode: TopBarMode) {
        topBarMode = mode
    }

    func toggleCenterGuides() {
        hasCenterGuides.toggle()
    }
}

class LayoutGridView: PassThroughView, NibOwnerLoadable {
    private var model: LayoutGridModel { LayoutGridModel.shared }
    private var cancellables = Set<AnyCancellable>()

    // MARK: - IBOutlets
    @IBOutlet private weak var gridView: UIView!

    // Main Guides
    @IBOutlet private weak var leftSafeAreaGuide: Guide!
    @IBOutlet private weak var leftMarginGuide: Guide!
    @IBOutlet private weak var rightMarginGuide: Guide!
    @IBOutlet private weak var bottomMarginGuide: Guide!
    @IBOutlet private weak var hCenterGuide: Guide!
    @IBOutlet private weak var vCenterGuide: Guide!
    @IBOutlet private var centerGuides: [UIView]!

    // HUD
    @IBOutlet private weak var missionButtonVGuide: Guide!
    @IBOutlet private weak var missionButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var missionButtonGuideContainer: MainContainerStackView!
    @IBOutlet private weak var bottomBarSpacingGuide: Guide!
    @IBOutlet private var hudGuides: [UIView]!

    // Top Bars
    @IBOutlet private weak var topBarGuide: Guide!
    @IBOutlet private weak var topBarTopPaddingGuide: Guide!
    @IBOutlet private weak var topBarBottomPaddingGuide: Guide!

    // Bottom Bar
    @IBOutlet private weak var bottomButtonsGuide: Guide!
    @IBOutlet private weak var bottomButtonsSpacingGuide: Guide!
    @IBOutlet private var bottomGuides: [UIView]!

    // Panels
    @IBOutlet private weak var leftPanelGuide: Guide!
    @IBOutlet private weak var leftPanelTrailingGuide: Guide!
    @IBOutlet private weak var rightPanelGuide: Guide!
    @IBOutlet private weak var rightPanelLeadingGuide: Guide!
    @IBOutlet private weak var rightPanelButtonsGuide0: Guide!
    @IBOutlet private weak var rightPanelButtonsGuide1: Guide!
    @IBOutlet private weak var rightPanelButtonsGuide2: Guide!
    @IBOutlet private weak var rightPanelButtonsSpacingGuide0: Guide!
    @IBOutlet private weak var rightPanelButtonsSpacingGuide1: Guide!
    @IBOutlet private weak var rightPanelButtonsSpacingGuide2: Guide!
    @IBOutlet private var leftPanelGuides: [UIView]!
    @IBOutlet private var rightPanelGuides: [UIView]!

    // MARK: - Constants
    private enum Constants {
        static let safeAreaColor = ColorName(rgbaValue: 0xEE9027FF).color
        static let marginColor = ColorName(rgbaValue: 0x612DE8FF).color
        static let spacingColor = ColorName(rgbaValue: 0xE73C46FF).color
        static let innerMarginColor = ColorName(rgbaValue: 0x57B56EFF).color
        static let guideColor = ColorName(rgbaValue: 0x4FB0FBFF).color.withAlphaComponent(0.5)
    }

    // MARK: - Init
    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepareGuides()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareGuides()
    }

    func overlay(on viewController: UIViewController) {
        viewController.view.addWithConstraints(subview: self)
    }
}

// MARK: - Layout
private extension LayoutGridView {
    func prepareGuides() {
        loadNibContent()

        // Top Bar
        topBarGuide.setup(height: Layout.hudTopBarHeight(isRegularSizeClass), color: Constants.innerMarginColor)
        topBarTopPaddingGuide.setup(height: Layout.hudTopBarInnerMargins(isRegularSizeClass).top, color: Constants.innerMarginColor)
        topBarBottomPaddingGuide.setup(color: Constants.innerMarginColor)

        // Main Guides
        bottomMarginGuide.setup(height: Layout.mainBottomMargin(isRegularSizeClass), color: Constants.safeAreaColor)
        leftSafeAreaGuide.setup(width: Layout.leftSafeAreaPadding, color: Constants.safeAreaColor)
        leftMarginGuide.setup(width: Layout.mainPadding(isRegularSizeClass), color: Constants.marginColor)
        rightMarginGuide.setup(width: Layout.mainPadding(isRegularSizeClass), color: Constants.marginColor)
        hCenterGuide.setup(color: Constants.guideColor)
        vCenterGuide.setup(color: Constants.guideColor)

        // HUD
        missionButtonGuideContainer.hasMinLeftPadding = true
        missionButtonGuideContainer.enabledMargins = [.left]
        missionButtonGuideContainer.spacing = 0
        missionButtonWidthConstraint.constant = Layout.buttonIntrinsicHeight(isRegularSizeClass)
        missionButtonVGuide.setup(color: Constants.guideColor)
        bottomBarSpacingGuide.setup(width: Layout.mainSpacing(isRegularSizeClass), color: Constants.spacingColor)

        // Bottom Buttons
        bottomButtonsGuide.setup(height: Layout.buttonIntrinsicHeight(isRegularSizeClass))
        bottomButtonsSpacingGuide.setup(height: Layout.mainSpacing(isRegularSizeClass), color: Constants.spacingColor)

        // Panels
        leftPanelGuide.setup(width: Layout.sidePanelWidth(isRegularSizeClass), color: Constants.marginColor)
        rightPanelGuide.setup(width: Layout.sidePanelWidth(isRegularSizeClass), color: Constants.marginColor)
        leftPanelTrailingGuide.setup(width: Layout.mainPadding(isRegularSizeClass), color: Constants.marginColor)
        rightPanelLeadingGuide.setup(width: Layout.mainPadding(isRegularSizeClass), color: Constants.marginColor)
        rightPanelButtonsGuide0.setup(height: Layout.buttonIntrinsicHeight(isRegularSizeClass))
        rightPanelButtonsSpacingGuide0.setup(height: Layout.mainSpacing(isRegularSizeClass), color: Constants.spacingColor)
        rightPanelButtonsSpacingGuide1.setup(color: Constants.spacingColor)
        rightPanelButtonsSpacingGuide2.setup(color: Constants.spacingColor)

        model.$areas
            .sink { [unowned self] areas in
                updateAreas(areas)
            }
            .store(in: &cancellables)

        model.$hasCenterGuides
            .sink { [unowned self] show in
                updateCenterGuides(show)
            }
            .store(in: &cancellables)

        model.$topBarMode
            .sink { [unowned self] mode in
                updateTopBarGuides(mode)
            }
            .store(in: &cancellables)

        model.$isShown
            .sink { [unowned self] show in
                showGrid(show)
            }
            .store(in: &cancellables)
    }

    func showGrid(_ show: Bool) {
        gridView.alpha = show ? 1 : 0
    }

    func updateAreas(_ areas: Set<LayoutGuideArea>) {
        topBarGuide.animateIsHiddenInStackView(!areas.contains(.topBar))
        _ = bottomGuides.map { $0.animateIsHiddenInStackView(!areas.contains(.bottomBar)) }
        _ = rightPanelGuides.map { $0.animateIsHiddenInStackView(!areas.contains(.rightPanel)) }
        _ = leftPanelGuides.map { $0.animateIsHiddenInStackView(!areas.contains(.leftPanel)) }
    }

    func updateTopBarGuides(_ mode: TopBarMode) {
        _ = hudGuides.map { $0.animateIsHiddenInStackView(mode != .hud) }
        let height = mode == .hud ? Layout.hudTopBarHeight(isRegularSizeClass) : Layout.fileNavigationBarHeight(isRegularSizeClass)
        let margin = mode == .hud ? Layout.hudTopBarInnerMargins(isRegularSizeClass).top : Layout.fileNavigationBarInnerMargins(isRegularSizeClass).top

        guard let heightConstraint = topBarGuide.constraints.filter({ $0.identifier == Guide.Constants.heightId }).first,
              let marginConstraint = topBarTopPaddingGuide.constraints.filter({ $0.identifier == Guide.Constants.heightId }).first else {
            return
        }
        heightConstraint.constant = height
        marginConstraint.constant = margin
        UIView.animate(withDuration: Style.shortAnimationDuration) {
            self.layoutIfNeeded()
        }
    }

    func updateCenterGuides(_ show: Bool) {
        _ = centerGuides.map { $0.animateIsHiddenInStackView(!show) }
    }
}

private class Guide: UIView {
    var color: UIColor?
    var width: CGFloat?
    var height: CGFloat?

    // For dynamic changing only.
    enum Constants {
        static let widthId = "widthId"
        static let heightId = "heightId"
    }

    func setup(width: CGFloat? = nil, height: CGFloat? = nil, color: UIColor? = nil) {
        isUserInteractionEnabled = false

        if let width = width {
            let widthConstraint = widthAnchor.constraint(equalToConstant: width)
            widthConstraint.identifier = Constants.widthId
            widthConstraint.isActive = true
        }
        if let height = height {
            let heightConstraint = heightAnchor.constraint(equalToConstant: height)
            heightConstraint.identifier = Constants.heightId
            heightConstraint.isActive = true
        }

        guard let color = color else { return }

        backgroundColor = color.withAlphaComponent(0.15)
        layer.borderWidth = 1
        layer.borderColor = color.cgColor
    }
}

class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        guard hitView != self else { return nil }
        return hitView
    }
}
