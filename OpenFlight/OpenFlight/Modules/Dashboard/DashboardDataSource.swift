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

import Foundation

/// Data source of dash board View controller
/// Handle all behaviours of displaying sections and items
struct DashboardDataSource {

    /// Sections displayed on controller
    var sections: [Section] {
        [.header, .content, .footer]
    }

    /// Subscript to get item if needed
    subscript(section: Int, index: Int) -> Item? {
        sections[safeIndex: section]?.items[safeIndex: index]
    }

    /// Subscript to get array of items
    subscript(section: Int) -> [Item] {
        sections[safeIndex: section]?.items ?? []
    }

    /// All kind of Sections that displayed on `DashboardViewController`
    enum Section {
        case header
        case content
        case footer

        var items: [Item] {
            switch self {
            case .header:
                return [.header(.logo), .header(.header)]
            case .footer:
                return [.footer]
            case .content:
                return [
                    .content(.dashboardMyAccount),
                    .content(.remoteInfos),
                    .content(.droneInfos),
                    .content(.settings),
                    .content(.myFlights),
                    .content(.projectManager),
                    .content(.galleryMedia)
                ]
            }
        }
    }

    /// All kind of Items that displayed on each `Section`
    enum Item {
        case content(ContentItemType)
        case header(DashboardItemCellType)
        case footer
    }

    /// Content Item Type
    enum ContentItemType {
        case dashboardMyAccount
        case remoteInfos
        case droneInfos
        case myFlights
        case galleryMedia
        case settings
        case projectManager
    }
}

extension DashboardDataSource {
    // MARK: - Private Enums
    fileprivate enum SizeConstants {
        static let headerHeight: CGFloat = 44.0
        static let footerHeight: CGFloat = 35.0
        static let commonCellSpacing: CGFloat = 10.0
    }

    fileprivate enum RegularSizeConstants {
        static let headerHeight: CGFloat = 55.0
        static let footerHeight: CGFloat = 55.0
        static let commonCellSpacing: CGFloat = 15.0
        static let headerFooterHeightPercentage: CGFloat = 0.2
        static let contentHeightPercentage: CGFloat = 0.6
        static let bottomInset: CGFloat = 20.0
    }

    fileprivate enum Constants {
        static let halfScreen: CGFloat = 2.0
        static let thirdScreen: CGFloat = 3.0
        static let quarterScreen: CGFloat = 4.0
        static let numberOfContentRows: CGFloat = 2.0
        static let numberOfVerticalMargins: CGFloat = 2.0
        static let heightLimit: CGFloat = 390
    }
}

// MARK: - Extension Section
extension DashboardDataSource.Section {
    /// Minimum space between cells
    func getMinimumCellSpacing(_ isRegularSizeClass: Bool) -> CGFloat {
        return isRegularSizeClass
            ? DashboardDataSource.RegularSizeConstants.commonCellSpacing
            : DashboardDataSource.SizeConstants.commonCellSpacing
    }

    /// Get size of each insets from given width
    func getComputedInsets(width: CGFloat, height: CGFloat, isRegularSizeClass: Bool, section: DashboardDataSource.Section) -> UIEdgeInsets {

        var cellSpacing: CGFloat {
            return isRegularSizeClass
                ? DashboardDataSource.RegularSizeConstants.commonCellSpacing
                : DashboardDataSource.SizeConstants.commonCellSpacing
        }

        var topInset: CGFloat {
            if isRegularSizeClass {
                switch section {
                case .header:
                    let nbItems = DashboardDataSource.Constants.halfScreen
                    let heightPercentage = DashboardDataSource.RegularSizeConstants.headerFooterHeightPercentage
                    let headerContentHeight = DashboardDataSource.RegularSizeConstants.headerHeight
                    return ((height * heightPercentage) - (cellSpacing * nbItems)) - headerContentHeight
                default:
                    return 0
                }
            } else {
                switch section {
                case .header:
                    return Layout.mainPadding(false)
                default:
                    return 0
                }
            }
        }

        var bottomInset: CGFloat {
            if isRegularSizeClass {
                switch section {
                case .header,
                     .content:
                    return DashboardDataSource.RegularSizeConstants.commonCellSpacing
                case .footer:
                    return 0
                }
            } else {
                switch section {
                case .content,
                     .footer:
                    return Layout.mainPadding(isRegularSizeClass)
                default:
                    return DashboardDataSource.SizeConstants.commonCellSpacing
                }
            }
        }

        return UIEdgeInsets(top: topInset,
                            left: 0,
                            bottom: bottomInset,
                            right: 0)
    }
}

// swiftlint:disable superfluous_disable_command file_length implicit_return
// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length

// MARK: - Extension Item
extension DashboardDataSource.Item {
    /// Get size of each item from given width
    func getComputedSize(width: CGFloat, height: CGFloat, isRegularSizeClass: Bool) -> CGSize {
        var computedHeight: CGFloat
        var computedWidth: CGFloat

        /// Spacing of the horizontal cell.
        var cellSpacing: CGFloat {
            return isRegularSizeClass
                ? DashboardDataSource.RegularSizeConstants.commonCellSpacing
                : DashboardDataSource.SizeConstants.commonCellSpacing
        }

        switch self {
        case .header:
            computedHeight = isRegularSizeClass
                ? DashboardDataSource.RegularSizeConstants.headerHeight
                : DashboardDataSource.SizeConstants.headerHeight
            computedWidth = (width - (cellSpacing)) / DashboardDataSource.Constants.halfScreen

        case .footer:
            let bottomInset = DashboardDataSource.RegularSizeConstants.bottomInset
            let heightPercentage = DashboardDataSource.RegularSizeConstants.headerFooterHeightPercentage
            computedHeight = isRegularSizeClass
                ? height * heightPercentage - bottomInset
                : DashboardDataSource.SizeConstants.footerHeight
            computedWidth = width

        case let .content(contentType):
            let heightPercentage = DashboardDataSource.RegularSizeConstants.contentHeightPercentage
            if isRegularSizeClass {
                computedHeight = (height * heightPercentage - cellSpacing) / DashboardDataSource.Constants.numberOfContentRows
            } else {
                let footerTotalHeight = height > DashboardDataSource.Constants.heightLimit
                ? DashboardDataSource.SizeConstants.footerHeight + Layout.mainPadding(false)
                : Layout.mainSpacing(isRegularSizeClass)

                computedHeight = (height
                                  - DashboardDataSource.SizeConstants.headerHeight
                                  - footerTotalHeight
                                  - Layout.mainPadding(false)
                                  - Layout.mainSpacing(false) * DashboardDataSource.Constants.numberOfVerticalMargins
                                  - Layout.mainPadding(false))
                                  / DashboardDataSource.Constants.numberOfContentRows
            }
            switch contentType {
            case .galleryMedia,
                 .myFlights,
                 .projectManager:
                let nbItemsOnRow = DashboardDataSource.Constants.thirdScreen
                let cellWidth = (width - cellSpacing * (nbItemsOnRow - 1)) / nbItemsOnRow
                computedWidth = contentType == .myFlights ? cellWidth.rounded(.up) : cellWidth.rounded(.down)
            default:
                let nbItemsOnRow = DashboardDataSource.Constants.quarterScreen
                computedWidth = (width - cellSpacing * (nbItemsOnRow - 1)) / nbItemsOnRow
            }
        }
        return CGSize(width: computedWidth, height: computedHeight)
    }
}

fileprivate extension Array {
    subscript(safeIndex index: Int) -> Iterator.Element? {
        guard index >= 0, index < endIndex, index < count else {
            return nil
        }

        return self[index]
    }
}
