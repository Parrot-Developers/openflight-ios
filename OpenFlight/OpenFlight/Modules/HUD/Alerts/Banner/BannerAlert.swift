//    Copyright (C) 2022 Parrot Drones SAS
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

// MARK: - Constants

/// Banner alert behavior and UI constants.
public enum BannerAlertConstants {
    // MARK: Behavior
    /// The default on duration.
    static let defaultOnDuration: TimeInterval = 3
    /// The default on duration for critical severity.
    static let defaultCriticalOnDuration: TimeInterval = 30
    /// The default on duration for warning severity.
    static let defaultWarningOnDuration: TimeInterval = 30
    /// The default on duration for advice severity.
    static let defaultAdviceOnDuration: TimeInterval = 5
    /// The default snooze duration.
    static let defaultSnoozeDuration: TimeInterval = 120
    /// The default system sound ID for critical severity.
    static let defaultCriticalSystemSoundId: UInt32 = 1257
    /// The maximum number of alerts that can be simultaneously displayed on screen.
    static let visibleBannerAlertsMaxCount = 1

    // MARK: UI
    /// The default spacing between 2 banners.
    static let defaultSpacing: CGFloat = 8
    /// The default padding between banner icon/title and borders.
    static let defaultPadding: CGFloat = 8
    /// The padding between banner icon/title and borders for compact banners.
    static let compactPadding: CGFloat = 3
    /// The banner icon max size.
    static let iconMaxSize: CGFloat = 20
}

// MARK: - Protocol

/// The protocol defining a `BannerAlert`.
public protocol BannerAlert {
    /// The severity of the alert.
    var severity: BannerAlertSeverity { get }
    /// The content of the alert.
    var content: BannerAlertContent { get }
    /// The style of the alert.
    var style: BannerAlertStyle { get }
    /// The behavior of the alert.
    var behavior: BannerAlertBehavior { get }
    /// The priority of the alert (unused for now).
    var priority: Int { get }
}

// MARK: - Wrapper

/// A wrapper type for `BannerAlert` allowing `Equatable` protocol conformance.
public struct AnyBannerAlert: BannerAlert, CustomStringConvertible {
    public var uid: Int { hashValue }
    public var severity: BannerAlertSeverity { banner.severity }
    public var content: BannerAlertContent { banner.content }
    public var style: BannerAlertStyle { banner.style }
    public var behavior: BannerAlertBehavior { banner.behavior }
    public var priority: Int { banner.priority }

    public var description: String {
        String(describing: banner)
    }

    /// Constructor.
    ///
    /// - Parameter banner: the banner alert to wrap
    public init(_ banner: BannerAlert) {
        self.banner = banner
    }

    /// The wrapped banner alert.
    private let banner: BannerAlert
}

extension AnyBannerAlert: Equatable {
    public static func == (lhs: AnyBannerAlert, rhs: AnyBannerAlert) -> Bool {
        lhs.uid == rhs.uid
    }
}

extension AnyBannerAlert: Comparable {
    public static func < (lhs: AnyBannerAlert, rhs: AnyBannerAlert) -> Bool {
        // Banner alert comparison:
        // 1. First criteria is severity: `BannerAlertSeverity` comparison is already overloaded.
        //    => lhs has a lower severity than rhs if lhs.severity < rhs.severity.
        // 2. Second criteria is priority: lhs has a lower priority than rhs if rhs.priority < lhs.priority.
        //    (the lower the value, the higher the priority).
        (lhs.severity, rhs.priority) < (rhs.severity, lhs.priority)
    }
}

extension AnyBannerAlert: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(severity)
        hasher.combine(content)
        hasher.combine(style)
        hasher.combine(behavior)
        hasher.combine(priority)
    }
}

// MARK: - Convenience Array Extensions

extension Array where Element == AnyBannerAlert {
    /// Inserts a banner alert into a sorted banner alerts array.
    ///
    /// - Parameter element: the banner alert to insert
    mutating func sortedInsert(_ element: Element) {
        // Insert `element` right before the first element of same or lower severity.
        // (Array is already sorted, so all further elements are known to be of lower severity.)
        // Insert at the end of the array if no lower or equal severity element is found.
        let index = firstIndex(where: { $0.severity <= element.severity }) ?? count
        insert(element, at: index)
    }

    /// Removes all occurrences of a banner alert from array.
    ///
    /// - Parameter element: the banner alert to remove
    mutating func remove(_ element: Element) {
        removeAll(where: { $0 == element })
    }
}

// MARK: - Severity

public enum BannerAlertSeverity: Int, Equatable, Comparable, Hashable, CustomStringConvertible {
    /// The highest severity level.
    /// Mandatory alerts are displayed even if other alerts are already displayed.
    case mandatory = 1

    /// Critical level.
    /// Associated behavior: alert is displayed until explicitely removed or another critical alert raises.
    case critical

    /// Warning level.
    /// Associated behavior: alert is displayed until explicitely removed, `BannerAlertConstants.defaultWarningOnDuration`
    /// is elapsed, or a critical alert raises.
    case warning

    /// Advice level.
    /// Associated behavior: alert is displayed until `BannerAlertConstants.defaultAdviceOnDuration` is elapsed or a higher
    /// severity alert raises.
    case advice

    /// Lower than operator overload.
    public static func < (lhs: BannerAlertSeverity, rhs: BannerAlertSeverity) -> Bool {
        // `lhs` is lower than `rhs` if its rawValue is higher.
        lhs.rawValue > rhs.rawValue
    }

    /// The severity description.
    public var description: String {
        switch self {
        case .mandatory: return "mandatory"
        case .critical: return "critical"
        case .warning: return "warning"
        case .advice: return "advice"
        }
    }
}

// MARK: - Content

/// A banner alert content.
public struct BannerAlertContent: Hashable {
    /// The banner alert's icon.
    let icon: UIImage?
    /// The banner alert's title.
    let title: String

    /// Constructor.
    ///
    /// - Parameters:
    ///    - icon: the banner alert's icon
    ///    - title: the banner alert's title
    public init(icon: UIImage? = nil,
                title: String) {
        self.icon = icon
        self.title = title
    }
}

// MARK: - Style

/// A banner alert style.
public struct BannerAlertStyle: Hashable {
    /// The banner alert's icon color.
    let iconColor: UIColor
    /// The banner alert's title color.
    let titleColor: UIColor
    /// The banner alert's background color.
    let backgroundColor: UIColor
    /// The banner alert's horizontal content padding.
    let hPadding: CGFloat?
    /// The banner alert's vertical content padding.
    let vPadding: CGFloat?

    /// Constructor.
    ///
    /// - Parameters:
    ///    - iconColor: the banner alert's icon color
    ///    - titleColor: the banner alert's title color
    ///    - backgroundColor: the banner alert's background color
    ///    - hPadding: the banner alert's horizontal content padding
    ///    - vPadding: the banner alert's vertical content padding
    public init(iconColor: UIColor? = nil,
                titleColor: UIColor,
                backgroundColor: UIColor,
                hPadding: CGFloat? = nil,
                vPadding: CGFloat? = nil) {
        // Use `titleColor` for icon if no dedicated color is provided.
        self.iconColor = iconColor ?? titleColor
        self.titleColor = titleColor
        self.backgroundColor = backgroundColor
        self.hPadding = hPadding
        self.vPadding = vPadding
    }
}

// MARK: - Behavior

/// A banner alert behavior.
public struct BannerAlertBehavior: Hashable {
    /// The banner alert's on duration.
    /// Alert is displayed until removed if `nil`.
    let onDuration: TimeInterval?

    /// The banner alert's snooze duration.
    /// Alert can't be displayed even if triggered if snooze duration is not elapsed.
    let snoozeDuration: TimeInterval?

    /// The banner alert's haptic feedback type.
    /// No feedback is provided if `nil`.
    let feedbackType: UINotificationFeedbackGenerator.FeedbackType?

    /// The banner alert's system sound ID.
    /// No sound is played if `nil`.
    let systemSoundId: UInt32?

    /// Constructor.
    ///
    /// - Parameters:
    ///    - onDuration: the banner alert's on duration
    ///    - snoozeDuration: the banner alert's snooze duration
    ///    - feedbackType: the banner alert's haptic feedback type
    ///    - systemSoundId: the banner alert's system sound ID
    public init(onDuration: TimeInterval? = nil,
                snoozeDuration: TimeInterval? = nil,
                feedbackType: UINotificationFeedbackGenerator.FeedbackType? = nil,
                systemSoundId: UInt32? = nil) {
        self.onDuration = onDuration
        self.snoozeDuration = snoozeDuration
        self.feedbackType = feedbackType
        self.systemSoundId = systemSoundId
    }
}

// MARK: - Extensions

// Default implementation of banner alert parameters according to severity.
extension BannerAlertSeverity {
    public var style: BannerAlertStyle {
        switch self {
        case .mandatory:
            return .init(titleColor: .black,
                         backgroundColor: ColorName.highlightColor.color)
        case .critical:
            return .init(titleColor: .white,
                         backgroundColor: ColorName.errorColor.color)
        case .warning:
            return .init(iconColor: ColorName.warningColor.color,
                         titleColor: .white,
                         backgroundColor: ColorName.black60.color)
        case .advice:
            return .init(titleColor: .black,
                         backgroundColor: .white)
        }
    }

    public var behavior: BannerAlertBehavior {
        BannerAlertBehavior(onDuration: onDuration,
                            snoozeDuration: snoozeDuration,
                            feedbackType: feedbackType,
                            systemSoundId: systemSoundId)
    }

    public var onDuration: TimeInterval? {
        switch self {
        case .mandatory: return nil
        case .critical: return BannerAlertConstants.defaultCriticalOnDuration
        case .warning: return BannerAlertConstants.defaultWarningOnDuration
        case .advice: return BannerAlertConstants.defaultAdviceOnDuration
        }
    }

    public var snoozeDuration: TimeInterval? {
        switch self {
        case .mandatory: return nil
        case .critical, .warning: return BannerAlertConstants.defaultSnoozeDuration
        case .advice: return nil
        }
    }

    public var feedbackType: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .mandatory: return nil
        case .critical: return .error
        case .warning: return .warning
        case .advice: return nil
        }
    }

    public var systemSoundId: UInt32? {
        switch self {
        case .mandatory: return nil
        case .critical: return BannerAlertConstants.defaultCriticalSystemSoundId
        case .warning: return nil
        case .advice: return nil
        }
    }
}

/// Default implementation of `BannerAlert` protocol.
public extension BannerAlert {
    var style: BannerAlertStyle { severity.style }
    var behavior: BannerAlertBehavior { severity.behavior }
    var priority: Int { 0 }
}

// MARK: - Default protocol conformance

/// A struct implementing the `BannerAlert` protocol.
/// Can be used for custom banner instantiations.
public struct BannerAlertImpl: BannerAlert, Equatable {
    public let severity: BannerAlertSeverity
    public let content: BannerAlertContent
    public let style: BannerAlertStyle
    public let behavior: BannerAlertBehavior
    public let priority: Int
}
