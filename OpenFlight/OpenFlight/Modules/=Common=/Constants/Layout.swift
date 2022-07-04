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

public enum Layout {
    // MARK: - Global Spacings
    /// Main bottom margin.
    public static func mainBottomMargin(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? mainBottomMargins.regular : mainBottomMargins.compact
    }
    /// Left safe area padding.
    /// (Exposed for layout grid debug display only.)
    public static var leftSafeAreaPadding: CGFloat { UIDevice.current.hasLeftSafeAreaInset ? leftSafeAreaMargin : 0 }
    /// Main padding.
    public static func mainPadding(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? mainPaddings.regular : mainPaddings.compact
    }
    /// Main spacing.
    public static func mainSpacing(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? mainSpacings.regular : mainSpacings.compact
    }
    /// Main container inner margins.
    public static func mainContainerInnerMargins(_ isRegularSizeClass: Bool,
                                                 screenBorders: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom],
                                                 hasMinLeftPadding: Bool = false) -> NSDirectionalEdgeInsets {
        isRegularSizeClass
        ? mainContainerInnerEdges(screenBorders: screenBorders, hasMinLeftPadding: hasMinLeftPadding).regular
        : mainContainerInnerEdges(screenBorders: screenBorders, hasMinLeftPadding: hasMinLeftPadding).compact
    }

    /// Table view cell container inset.
    public static func tableViewCellContainerInset(_ isRegularSizeClass: Bool) -> UIEdgeInsets {
        isRegularSizeClass
        ? tableViewCellContainerInsets.regular
        : tableViewCellContainerInsets.compact
    }

    // MARK: - Information Screen Spacings
    /// leftSafeAreaMargin mainPaddings leftInfoMargin
    public static func leftInfoContainerMargin(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? leftInfoScreenMargin.regular
        : leftSafeAreaMaxPaddings.compact + leftInfoScreenMargin.compact
    }
    /// Information container inner margins.
    public static func infoContainerInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        .init(top: 0,
              leading: leftInfoContainerMargin(isRegularSizeClass),
              bottom: 0,
              trailing: mainPadding(isRegularSizeClass))
    }

    // MARK: - Dashboard Screen Spacings
    public static func dashboardContainerInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass
        ? .init(top: 0,
                leading: 40,
                bottom: 0,
                trailing: 40)
        : .init(top: 0,
                leading: UIDevice.current.hasLeftSafeAreaInset ? leftSafeAreaMargin + Layout.mainPaddings.compact : Layout.mainPaddings.compact,
                bottom: 0,
                trailing: UIDevice.current.hasLeftSafeAreaInset ? leftSafeAreaMargin + Layout.mainPaddings.compact : Layout.mainPaddings.compact)
    }

    // MARK: - Buttons
    /// Button intrinsic height.
    public static func buttonIntrinsicHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? buttonIntrinsicHeights.regular : buttonIntrinsicHeights.compact
    }
    /// Back button intrinsic width.
    public static func backButtonIntrinsicWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? backButtonIntrinsicWidths.regular : backButtonIntrinsicWidths.compact
    }

    // MARK: - Side Panels
    /// Side panel width.
    public static func sidePanelWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? sidePanelWidths.regular : sidePanelWidths.compact
    }
    /// Left side panel width.
    public static func leftSidePanelWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        leftSafeAreaPadding + sidePanelWidth(isRegularSizeClass)
    }
    /// Navigation side panel width.
    public static func navigationSidePanelWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? navigationSidePanelWidths.regular : navigationSidePanelWidths.compact
    }
    /// Navigation side panel width.
    public static func navigationLeftSidePanelWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        leftSafeAreaPadding + navigationSidePanelWidth(isRegularSizeClass)
    }
    /// Right side panel inner margins.
    public static func rightSidePanelInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass ? rightSidePanelInnerEdges.regular : rightSidePanelInnerEdges.compact
    }
    /// Left side panel inner margins.
    public static func leftSidePanelInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass ? leftSidePanelInnerEdges.regular : leftSidePanelInnerEdges.compact
    }

    // MARK: - Top Bars
    /// File navigation bar height.
    public static func fileNavigationBarHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? fileNavigationBarHeights.regular : fileNavigationBarHeights.compact
    }
    /// File navigation bar inner margins.
    public static func fileNavigationBarInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass ? fileNavigationBarInnerEdges.regular : fileNavigationBarInnerEdges.compact
    }
    /// HUD top bar height.
    public static func hudTopBarHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? hudTopBarHeights.regular : hudTopBarHeights.compact
    }
    /// HUD top bar inner margins.
    public static func hudTopBarInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass ? hudTopBarInnerEdges.regular : hudTopBarInnerEdges.compact
    }
    /// HUD top bar panel width.
    public static func hudTopBarPanelWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? hudTopBarPanelWidths.regular : hudTopBarPanelWidths.compact
    }
    /// HUD top bar radar min width.
    public static func hudTopBarRadarMinWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? hudTopBarRadarMinWidths.regular : hudTopBarRadarMinWidths.compact
    }
    /// HUD top bar info container height.
    public static func hudTopBarInfoContainerHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? hudTopBarInfoContainerHeights.regular : hudTopBarInfoContainerHeights.compact
    }
    /// HUD top bar radar height.
    public static func hudTopBarRadarHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? hudTopBarRadarHeights.regular : hudTopBarRadarHeights.compact
    }
    /// Side navigation bar inner margins.
    /// (Use same margins as fileNavigationBar.)
    public static func sideNavigationBarInnerMargins(_ isRegularSizeClass: Bool) -> NSDirectionalEdgeInsets {
        isRegularSizeClass ? fileNavigationBarInnerEdges.regular : fileNavigationBarInnerEdges.compact
    }

    // MARK: - Bottom Bar
    /// Small bottom bar height.
    public static func smallBottomBarHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? smallBottomBarHeights.regular : smallBottomBarHeights.compact
    }

    // MARK: - CollectionViews
    /// File collection view columns count.
    public static func fileCollectionViewColumnsCount(_ isRegularSizeClass: Bool) -> Int {
        isRegularSizeClass ? fileCollectionViewColumnsCounts.regular : fileCollectionViewColumnsCounts.compact
    }
    /// File collection view cell height.
    public static func fileCollectionViewCellHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? fileCollectionViewCellHeights.regular : fileCollectionViewCellHeights.compact
    }
    /// File collection view content inset.
    public static func fileCollectionViewContentInset(_ isRegularSizeClass: Bool,
                                                      screenBorders: [NSLayoutConstraint.Attribute] = [.left, .top, .right, .bottom]) -> UIEdgeInsets {
        isRegularSizeClass
        ? fileCollectionViewContentInsets(screenBorders: screenBorders).regular
        : fileCollectionViewContentInsets(screenBorders: screenBorders).compact
    }
    /// File filter collection view cell height.
    static func fileFilterCollectionViewCellHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? fileFilterCollectionViewCellHeights.regular : fileFilterCollectionViewCellHeights.compact
    }

    // MARK: - TableViews
    /// Table view cell content inset.
    public static func tableViewCellContentInset(_ isRegularSizeClass: Bool,
                                                 screenBorders: [NSLayoutConstraint.Attribute] = []) -> UIEdgeInsets {
        isRegularSizeClass
        ? tableViewCellContentInsets(screenBorders: screenBorders).regular
        : tableViewCellContentInsets(screenBorders: screenBorders).compact
    }

    /// Settings table view cell spacing.
    public static func settingsTableViewCellSpacing(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? tableViewCellSettingsSpacings.regular : tableViewCellSettingsSpacings.compact
    }

    /// Table view cell settings content inset.
    public static func tableViewCellSettingsContentInset(_ isRegularSizeClass: Bool,
                                                         screenBorders: [NSLayoutConstraint.Attribute] = []) -> UIEdgeInsets {
        isRegularSizeClass
        ? tableViewCellSettingsContentInsets(screenBorders: screenBorders).regular
        : tableViewCellSettingsContentInsets(screenBorders: screenBorders).compact
    }

    // MARK: - Side Panel Settings
    /// Side Panel Setting Table view cell content inset.
    public static func sidePanelSettingTableViewCellContentInset(_ isRegularSizeClass: Bool) -> UIEdgeInsets {
        isRegularSizeClass
        ? sidePanelSettingTableViewCellContentInsets.regular
        : sidePanelSettingTableViewCellContentInsets.compact
    }
    /// Side Panel Setting Short TableViewCell height.
    public static func sidePanelSettingShortTableViewCellHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingShortTableViewCellHeights.regular
        : sidePanelSettingShortTableViewCellHeights.compact
    }
    /// Side Panel Setting Large TableViewCell height.
    public static func sidePanelSettingLargeTableViewCellHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingLargeTableViewCellHeights.regular
        : sidePanelSettingLargeTableViewCellHeights.compact
    }
    /// Side Panel Setting Text Segmented Control height.
    public static func sidePanelSettingTextSegmentsHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingTextSegmentsHeights.regular
        : sidePanelSettingTextSegmentsHeights.compact
    }
    /// Side Panel Setting Text Segmented Control with two segments width.
    public static func sidePanelSettingTwoSegmentsWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingTwoSegmentsWidths.regular
        : sidePanelSettingTwoSegmentsWidths.compact
    }
    /// Side Panel Setting Slider height.
    public static func sidePanelSettingSliderHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingSliderHeights.regular
        : sidePanelSettingSliderHeights.compact
    }
    /// Side Panel Setting Slider Item width.
    public static func sidePanelSettingSliderItemWidth(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingSliderItemWidths.regular
        : sidePanelSettingSliderItemWidths.compact
    }
    /// Side Panel Setting Short Segmented Control with pictos height.
    public static func sidePanelSettingShortPictoSegmentsHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingShortPictoSegmentsHeights.regular
        : sidePanelSettingShortPictoSegmentsHeights.compact
    }
    /// Side Panel Setting Large (> 3) Segmented Control with pictos height.
    public static func sidePanelSettingLargePictoSegmentsHeight(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass
        ? sidePanelSettingLargePictoSegmentsHeights.regular
        : sidePanelSettingLargePictoSegmentsHeights.compact
    }

    // MARK: - Fonts
    public static func capsFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? capsFontSizes.regular : capsFontSizes.compact
    }
    public static func caps2FontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? caps2FontSizes.regular : caps2FontSizes.compact
    }
    public static func currentFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? currentFontSizes.regular : currentFontSizes.compact
    }
    public static func modeFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? modeFontSizes.regular : modeFontSizes.compact
    }
    public static func bigFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? bigFontSizes.regular : bigFontSizes.compact
    }
    public static func readingTextFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? readingTextFontSizes.regular : readingTextFontSizes.compact
    }
    public static func titleFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? titleFontSizes.regular : titleFontSizes.compact
    }
    public static func subtitleFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? subtitleFontSizes.regular : subtitleFontSizes.compact
    }
    public static func smallTextFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? smallTextFontSizes.regular : smallTextFontSizes.compact
    }
    public static func topBarFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? topBarFontSizes.regular : topBarFontSizes.compact
    }
    public static func mediumFontSize(_ isRegularSizeClass: Bool) -> CGFloat {
        isRegularSizeClass ? mdeiumFontSizes.regular : mdeiumFontSizes.compact
    }
}
private extension Layout {
    // MARK: - Buttons
    /// Button intrinsic heights.
    static let buttonIntrinsicHeights: (compact: CGFloat, regular: CGFloat) = (50, 66)
    /// Back button intrinsic widths.
    static let backButtonIntrinsicWidths: (compact: CGFloat, regular: CGFloat) = (40, 50)

    // MARK: - Side Panels
    /// Side panel widths.
    static let sidePanelWidths: (compact: CGFloat, regular: CGFloat) = (200, 300)
    /// Navigation side panel widths.
    static let navigationSidePanelWidths: (compact: CGFloat, regular: CGFloat) = (158, 205)

    // MARK: - Global Spacings
    /// Main paddings.
    static let mainPaddings: (compact: CGFloat, regular: CGFloat) = (12, 20)
    /// Main spacings.
    static let mainSpacings: (compact: CGFloat, regular: CGFloat) = (10, 15)
    /// Bottom safe area margins.
    static let bottomSafeAreaMargins: (compact: CGFloat, regular: CGFloat) = (19, 20)
    /// Left safe area margin.
    static let leftSafeAreaMargin: CGFloat = 30
    /// Left safe area adjustment offset (needed because `leftSafeAreaMargin` is slightly narrower than actual notch).
    static let leftSafeAreaAdjustmentOffset: CGFloat = 4
    /// Safe area corners margin. Used to compensate rounded corners lost space.
    /// No margin needed for regular size because of the neglectable relative corners size.
    static let safeAreaCornersMargins: (CGFloat, CGFloat) = (12, 0)
    /// Main paddings.
    static let tableViewCellContainerLeftPadding: (compact: CGFloat, regular: CGFloat) = (15, 15)
    /// Main spacings.
    static let tableViewCellContainerSpacing: (compact: CGFloat, regular: CGFloat) = (10, 10)
    /// Table view cell settings spacing
    static let tableViewCellSettingsSpacings: (compact: CGFloat, regular: CGFloat) = (5, 10)

    // MARK: - Information screen Spacings
    /// Left safe area info margin.
    static let leftInfoScreenMargin: (compact: CGFloat, regular: CGFloat) = (20, 60)

    // MARK: - Top Bars
    /// File navigation bar paddings.
    static let fileNavigationBarPaddings: (compact: CGFloat, regular: CGFloat) = (8, 10)
    /// File navigation bar heights.
    static let fileNavigationBarHeights: (compact: CGFloat, regular: CGFloat) = (56, 70)
    /// HUD top bar heights.
    static let hudTopBarHeights: (compact: CGFloat, regular: CGFloat) = (40, 56)
    /// HUD top bar paddings.
    static let hudTopBarPaddings: (compact: CGFloat, regular: CGFloat) = (10, 18)
    /// HUD top bar panel widths.
    static let hudTopBarPanelWidths: (compact: CGFloat, regular: CGFloat) = (250, 300)
    /// HUD top bar radar min width.
    static let hudTopBarRadarMinWidths: (compact: CGFloat, regular: CGFloat) = (80, 80)
    /// HUD top bar info container heights.
    static let hudTopBarInfoContainerHeights: (compact: CGFloat, regular: CGFloat) = (80, 80)
    /// HUD top bar radar heights.
    static let hudTopBarRadarHeights: (compact: CGFloat, regular: CGFloat) = (80, 80)

    // MARK: - Bottom Bar
    /// Small bottom bar height.
    static let smallBottomBarHeights: (compact: CGFloat, regular: CGFloat) = (34, 40)

    // MARK: - CollectionViews
    /// File collection view columns counts.
    static let fileCollectionViewColumnsCounts: (compact: Int, regular: Int) = (3, 3)
    /// File collection view cell heights.
    static let fileCollectionViewCellHeights: (compact: CGFloat, regular: CGFloat) = (145, 188)
    /// File filter collection view cell heights.
    static let fileFilterCollectionViewCellHeights: (compact: CGFloat, regular: CGFloat) = (32, 38)

    // MARK: - Side Panel Settings
    /// Side Panel Setting TableViewCell paddings.
    static let sidePanelSettingTableViewCellPaddings: (compact: CGFloat, regular: CGFloat) = (5, 5)
    /// Side Panel Setting Short TableViewCell heights.
    static let sidePanelSettingShortTableViewCellHeights: (compact: CGFloat, regular: CGFloat) = (90, 117)
    /// Side Panel Setting Large TableViewCell heights.
    static let sidePanelSettingLargeTableViewCellHeights: (compact: CGFloat, regular: CGFloat) = (100, 130)
    /// Side Panel Setting  Segmented Control with 2 segments widths.
    static let sidePanelSettingTwoSegmentsWidths: (compact: CGFloat, regular: CGFloat) = (110, 143)
    /// Side Panel Setting Text Segmented Control heights.
    static let sidePanelSettingTextSegmentsHeights: (compact: CGFloat, regular: CGFloat) = (47, 61)
    /// Side Panel Setting Slider heights.
    static let sidePanelSettingSliderHeights: (compact: CGFloat, regular: CGFloat) = (57, 74)
    /// Side Panel Setting Slider Item widths.
    static let sidePanelSettingSliderItemWidths: (compact: CGFloat, regular: CGFloat) = (47, 61)
    /// Side Panel Setting Short Segmented Control with pictos heights.
    static let sidePanelSettingShortPictoSegmentsHeights: (compact: CGFloat, regular: CGFloat) = (57, 74)
    /// Side Panel Setting Large (> 3) Segmented Control with pictos heights.
    static let sidePanelSettingLargePictoSegmentsHeights: (compact: CGFloat, regular: CGFloat) = (45, 58)

    // MARK: - Fonts
    static let capsFontSizes: (compact: CGFloat, regular: CGFloat) = (11, 14)
    static let caps2FontSizes: (compact: CGFloat, regular: CGFloat) = (13, 17)
    static let currentFontSizes: (compact: CGFloat, regular: CGFloat) = (13, 16)
    static let modeFontSizes: (compact: CGFloat, regular: CGFloat) = (10, 13)
    static let bigFontSizes: (compact: CGFloat, regular: CGFloat) = (15, 18)
    static let readingTextFontSizes: (compact: CGFloat, regular: CGFloat) = (17, 22)
    static let titleFontSizes: (compact: CGFloat, regular: CGFloat) = (19, 25)
    static let subtitleFontSizes: (compact: CGFloat, regular: CGFloat) = (15, 19)
    static let smallTextFontSizes: (compact: CGFloat, regular: CGFloat) = (15, 19)
    static let topBarFontSizes: (compact: CGFloat, regular: CGFloat) = (15, 19)
    static let mdeiumFontSizes: (compact: CGFloat, regular: CGFloat) = (13, 16)

    // MARK: - Definitions
    /// Left safe area corners padding.
    static var safeAreaCornersPaddings: (compact: CGFloat, regular: CGFloat) {
        UIDevice.current.hasBottomSafeAreaInset ? safeAreaCornersMargins : (0, 0)
    }
    /// Left safe area min paddings.
    static var leftSafeAreaMinPaddings: (compact: CGFloat, regular: CGFloat) {
        (max(leftSafeAreaPadding + leftSafeAreaAdjustmentOffset, mainPaddings.compact), mainPaddings.regular)
    }
    /// Left safe area max padding.
    static var leftSafeAreaMaxPaddings: (compact: CGFloat, regular: CGFloat) {
        (leftSafeAreaPadding + mainPaddings.compact, mainPaddings.regular)
    }
    /// Main bottom margins.
    static var mainBottomMargins: (compact: CGFloat, regular: CGFloat) {
        UIDevice.current.hasBottomSafeAreaInset ? bottomSafeAreaMargins : mainPaddings
    }
    /// HUD top bar inner edges.
    static var hudTopBarInnerEdges: (compact: NSDirectionalEdgeInsets, regular: NSDirectionalEdgeInsets) {
        (.init(top: hudTopBarPaddings.compact,
               leading: safeAreaCornersPaddings.compact + mainPaddings.compact,
               bottom: hudTopBarPaddings.compact,
               trailing: safeAreaCornersPaddings.compact + mainPaddings.compact),
         .init(top: hudTopBarPaddings.regular,
               leading: safeAreaCornersPaddings.regular + mainPaddings.regular,
               bottom: hudTopBarPaddings.regular,
               trailing: safeAreaCornersPaddings.regular + mainPaddings.regular))
    }
    /// File navigation bar inner edges.
    static var fileNavigationBarInnerEdges: (compact: NSDirectionalEdgeInsets, regular: NSDirectionalEdgeInsets) {
        (.init(top: fileNavigationBarPaddings.compact,
               leading: safeAreaCornersPaddings.compact + mainPaddings.compact,
               bottom: fileNavigationBarPaddings.compact,
               trailing: safeAreaCornersPaddings.compact + mainPaddings.compact),
         .init(top: fileNavigationBarPaddings.regular,
               leading: safeAreaCornersPaddings.regular + mainPaddings.regular,
               bottom: fileNavigationBarPaddings.regular,
               trailing: safeAreaCornersPaddings.regular + mainPaddings.regular))
    }
    /// Right side panel inner edges.
    static var rightSidePanelInnerEdges: (compact: NSDirectionalEdgeInsets, regular: NSDirectionalEdgeInsets) {
        mainContainerInnerEdges(screenBorders: [.bottom])
    }
    /// Left side panel inner edges.
    static var leftSidePanelInnerEdges: (compact: NSDirectionalEdgeInsets, regular: NSDirectionalEdgeInsets) {
        mainContainerInnerEdges()
    }
    /// Main container inner edges.
    static func mainContainerInnerEdges(screenBorders: [NSLayoutConstraint.Attribute] = [.left, .bottom],
                                        hasMinLeftPadding: Bool = false) -> (compact: NSDirectionalEdgeInsets,
                                                                             regular: NSDirectionalEdgeInsets) {
        (.init(top: mainPaddings.compact,
               leading: screenBorders.contains(.left)
               ? hasMinLeftPadding ? leftSafeAreaMinPaddings.compact : leftSafeAreaMaxPaddings.compact
               : mainPaddings.compact,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.compact : mainPaddings.compact,
               trailing: mainPaddings.compact),
         .init(top: mainPaddings.regular,
               leading: screenBorders.contains(.left)
               ? hasMinLeftPadding ? leftSafeAreaMinPaddings.regular : leftSafeAreaMaxPaddings.regular
               : mainPaddings.regular,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.regular : mainPaddings.regular,
               trailing: mainPaddings.regular))
    }
    /// Table view cell container insets.
    static var tableViewCellContainerInsets: (compact: UIEdgeInsets, regular: UIEdgeInsets) {
        (.init(top: tableViewCellContainerSpacing.compact,
               left: tableViewCellContainerLeftPadding.compact,
               bottom: tableViewCellContainerSpacing.compact,
               right: tableViewCellContainerSpacing.compact),
         .init(top: tableViewCellContainerSpacing.regular,
               left: tableViewCellContainerLeftPadding.regular,
               bottom: tableViewCellContainerSpacing.regular,
               right: tableViewCellContainerSpacing.regular))
    }
    /// File collectionView content insets.
    static func fileCollectionViewContentInsets(screenBorders: [NSLayoutConstraint.Attribute] = [.left, .bottom]) -> (compact: UIEdgeInsets,
                                                                                                                      regular: UIEdgeInsets) {
        (.init(top: mainPaddings.compact,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.compact : mainPaddings.compact,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.compact : mainPaddings.compact,
               right: mainPaddings.compact),
         .init(top: mainPaddings.regular,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.regular : mainPaddings.regular,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.regular : mainPaddings.regular,
               right: mainPaddings.regular))
    }
    /// TableViewCell content insets.
    static func tableViewCellContentInsets(screenBorders: [NSLayoutConstraint.Attribute] = []) -> (compact: UIEdgeInsets,
                                                                                                   regular: UIEdgeInsets) {
        (.init(top: mainSpacings.compact,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.compact : mainPaddings.compact,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.compact : mainSpacings.compact,
               right: mainPaddings.compact),
         .init(top: mainSpacings.regular,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.regular : mainPaddings.regular,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.regular : mainSpacings.regular,
               right: mainPaddings.regular))
    }
    /// TableViewCell settings content insets.
    static func tableViewCellSettingsContentInsets(screenBorders: [NSLayoutConstraint.Attribute] = []) -> (compact: UIEdgeInsets,
                                                                                                           regular: UIEdgeInsets) {
        (.init(top: tableViewCellSettingsSpacings.compact,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.compact : mainPaddings.compact,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.compact : tableViewCellSettingsSpacings.compact,
               right: mainPaddings.compact),
         .init(top: tableViewCellSettingsSpacings.regular,
               left: screenBorders.contains(.left) ? leftSafeAreaMaxPaddings.regular : mainPaddings.regular,
               bottom: screenBorders.contains(.bottom) ? mainBottomMargins.regular : tableViewCellSettingsSpacings.regular,
               right: mainPaddings.regular))
    }
    /// sidePanelSettingTableViewCell content insets.
    static var sidePanelSettingTableViewCellContentInsets: (compact: UIEdgeInsets,
                                                            regular: UIEdgeInsets) {
        (.init(top: mainSpacings.compact,
               left: sidePanelSettingTableViewCellPaddings.compact,
               bottom: mainSpacings.compact,
               right: sidePanelSettingTableViewCellPaddings.compact),
         .init(top: mainSpacings.regular,
               left: sidePanelSettingTableViewCellPaddings.regular,
               bottom: mainSpacings.regular,
               right: sidePanelSettingTableViewCellPaddings.regular))
    }
}
