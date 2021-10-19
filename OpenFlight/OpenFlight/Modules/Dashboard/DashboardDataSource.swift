// Copyright (C) 2021 Parrot Drones SAS
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
//                    Uncomment to display PGY debug cell
//                    .content(.photogrammetryDebug)
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
        case photogrammetryDebug
        case settings
        case projectManager
    }
}

extension DashboardDataSource {
    // MARK: - Private Enums
    fileprivate enum SizeConstants {
        static let topInset: CGFloat = 0.0
        static let commonCellSpacing: CGFloat = 10.0
        static let headerHeight: CGFloat = 44.0
        static let footerHeight: CGFloat = 35.0
        static let horizontalCellSpacing: CGFloat = 10.0
    }

    fileprivate enum RegularSizeConstants {
        static let headerHeight: CGFloat = 55.0
        static let footerHeight: CGFloat = 35.0
        static let horizontalCellSpacing: CGFloat = 15.0
    }

    fileprivate enum LandscapeRegularSizeConstants {
        static let topInset: CGFloat = 61.0
        static let cellHeight: CGFloat = 230.0
        static let cellWidth: CGFloat = 230.0
    }

    fileprivate enum PortraitRegularSizeConstants {
        static let topInset: CGFloat = 10.0
        static let cellHeight: CGFloat = 204.0
        static let cellWidth: CGFloat = 316.0
    }

    fileprivate enum LandscapeSizeConstants {
        static let cellHeight: CGFloat = 140.0
        static let cellCompactWidth: CGFloat = 152.0
        static let cellRegularWidth: CGFloat = 164.0
        static let regularScreenSizeLimit: CGFloat = 685.0
    }

    fileprivate enum PortraitSizeConstants {
        static let cellCompactHeight: CGFloat = 141.0
        static let cellRegularHeight: CGFloat = 158.0
        static let cellWidth: CGFloat = 162.0
    }

    fileprivate enum Constants {
        static let halfScreen: CGFloat = 2.0
        static let thirdScreen: CGFloat = 3.0
        static let quarterScreen: CGFloat = 4.0
    }
}

// MARK: - Extension Section
extension DashboardDataSource.Section {
    /// minimumInteritemSpacing of each section
    var minimumInteritemSpacing: CGFloat {
        return DashboardDataSource.SizeConstants.commonCellSpacing
    }

    /// minimumLineSpacing of each section
    var minimumLineSpacing: CGFloat {
        return DashboardDataSource.SizeConstants.commonCellSpacing
    }

    /// Get size of each insets from given width
    func getComputedInsets(width: CGFloat, height: CGFloat, isRegularSizeClass: Bool) -> UIEdgeInsets {
        /// Width of one cell.
        var cellWidth: CGFloat {
            if isRegularSizeClass {
                return UIApplication.isLandscape
                    ? DashboardDataSource.LandscapeRegularSizeConstants.cellWidth
                    : DashboardDataSource.PortraitRegularSizeConstants.cellWidth
            } else {
                return UIApplication.isLandscape
                    ? (width > DashboardDataSource.LandscapeSizeConstants.regularScreenSizeLimit
                        ? DashboardDataSource.LandscapeSizeConstants.cellRegularWidth
                        : DashboardDataSource.LandscapeSizeConstants.cellCompactWidth)
                    : DashboardDataSource.PortraitSizeConstants.cellWidth
            }
        }

        var horizontalCellSpacing: CGFloat {
            return isRegularSizeClass
                ? DashboardDataSource.RegularSizeConstants.horizontalCellSpacing
                : DashboardDataSource.SizeConstants.horizontalCellSpacing
        }

        var topInset: CGFloat {
            return isRegularSizeClass
                ? (UIApplication.isLandscape
                    ? DashboardDataSource.LandscapeRegularSizeConstants.topInset
                    : DashboardDataSource.PortraitRegularSizeConstants.topInset)
                : DashboardDataSource.SizeConstants.topInset
        }

        let nbColumns = UIApplication.isLandscape
            ? DashboardDataSource.Constants.quarterScreen
            : DashboardDataSource.Constants.halfScreen
        let collectionWidth = (nbColumns * cellWidth) + ((nbColumns - 1) * horizontalCellSpacing)
        let insets = (width - collectionWidth) / DashboardDataSource.Constants.halfScreen
        return UIEdgeInsets(top: topInset,
                            left: insets,
                            bottom: DashboardDataSource.SizeConstants.commonCellSpacing,
                            right: insets)
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
        var horizontalCellSpacing: CGFloat {
            return isRegularSizeClass
                ? DashboardDataSource.RegularSizeConstants.horizontalCellSpacing
                : DashboardDataSource.SizeConstants.horizontalCellSpacing
        }

        /// Width of one cell.
        var cellWidth: CGFloat {
            if isRegularSizeClass {
                return UIApplication.isLandscape
                    ? DashboardDataSource.LandscapeRegularSizeConstants.cellWidth
                    : DashboardDataSource.PortraitRegularSizeConstants.cellWidth
            } else {
                return UIApplication.isLandscape
                    ? (width > DashboardDataSource.LandscapeSizeConstants.regularScreenSizeLimit
                        ? DashboardDataSource.LandscapeSizeConstants.cellRegularWidth
                        : DashboardDataSource.LandscapeSizeConstants.cellCompactWidth)
                    : DashboardDataSource.PortraitSizeConstants.cellWidth
            }
        }

        /// Width of one cell.
        var cellHeight: CGFloat {
            if isRegularSizeClass {
                return UIApplication.isLandscape
                    ? DashboardDataSource.LandscapeRegularSizeConstants.cellHeight
                    : DashboardDataSource.PortraitRegularSizeConstants.cellHeight
            } else {
                return UIApplication.isLandscape
                    ? DashboardDataSource.LandscapeSizeConstants.cellHeight
                    : (width > DashboardDataSource.LandscapeSizeConstants.regularScreenSizeLimit
                        ? DashboardDataSource.PortraitSizeConstants.cellRegularHeight
                        : DashboardDataSource.PortraitSizeConstants.cellCompactHeight)
            }
        }

        if UIApplication.isLandscape {
            let nbColumns = DashboardDataSource.Constants.quarterScreen
            let collectionWidth = (nbColumns * cellWidth) + ((nbColumns - 1) * horizontalCellSpacing)
            switch self {
            case .header:
                computedHeight = DashboardDataSource.SizeConstants.headerHeight
                computedWidth = (collectionWidth - horizontalCellSpacing) / DashboardDataSource.Constants.thirdScreen
            case .footer:
                computedHeight = DashboardDataSource.SizeConstants.footerHeight
                computedWidth = collectionWidth
            case let .content(contentType):
                computedHeight = cellHeight
                switch contentType {
                case .galleryMedia,
                     .myFlights,
                     .projectManager:
                    let nbItemsOnRow = DashboardDataSource.Constants.thirdScreen
                    computedWidth = (collectionWidth - horizontalCellSpacing * (nbItemsOnRow - 1)) / nbItemsOnRow
                default:
                    computedWidth = cellWidth
                }
            }
        } else {
            let nbColumns = DashboardDataSource.Constants.halfScreen
            let collectionWidth = (nbColumns * cellWidth) + ((nbColumns - 1) * horizontalCellSpacing)
            switch self {
            case let .header(headerType):
                computedHeight = DashboardDataSource.SizeConstants.headerHeight
                switch headerType {
                case .logo:
                    computedWidth = (collectionWidth - horizontalCellSpacing)
                        * DashboardDataSource.Constants.thirdScreen / DashboardDataSource.Constants.quarterScreen
                case .header:
                    computedWidth = (collectionWidth - horizontalCellSpacing)
                        / DashboardDataSource.Constants.quarterScreen
                }
            case .footer:
                computedHeight = DashboardDataSource.SizeConstants.footerHeight
                computedWidth = collectionWidth
            case let .content(contentType):
                computedHeight = cellHeight
                switch contentType {
                case .myFlights,
                     .galleryMedia,
                     .projectManager:
                    // Set content width to the whole screen.
                    computedWidth = collectionWidth
                default:
                    computedWidth = cellWidth
                }
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
