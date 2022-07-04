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

import Combine
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "BannerAlertManagerService")
}

public enum BannerAlertMode: Int {
    /// Alert is displayed on screen as soon as it triggers.
    case full
    /// Alert is hidden event if present in stack.
    case hidden
}

// MARK: - Protocol

/// The protocol defining the baner alert manager service.
public protocol BannerAlertManagerService: AnyObject {
    /// The banners display mode publisher.
    var bannersModePublisher: AnyPublisher<BannerAlertMode, Never> { get }

    /// The banners stack publisher.
    var bannersPublisher: AnyPublisher<[AnyBannerAlert], Never> { get }

    /// The container frame publisher.
    var containerPublisher: AnyPublisher<CGRect, Never> { get }

    /// Sets the banners display mode.
    ///
    /// - Parameter mode: the banner alert display mode to set
    func setMode(_ mode: BannerAlertMode)

    /// Sets the banners container frame.
    ///
    /// - Parameter frame: the banners container frame to set
    func setContainer(frame: CGRect)

    /// Adds a banner alert to the stack.
    ///
    /// - Parameter banner: the banner alert to add
    func show(_ banner: BannerAlert)

    /// Removes a banner alert from the stack.
    ///
    /// - Parameter banner: the banner alert to remove
    func hide(_ banner: BannerAlert)

    /// Removes a banner alerts array from the stack.
    ///
    /// - Parameter banners: the banner alerts array to remove
    func hide(_ banners: [BannerAlert])

    /// Clear all banner alerts.
    func clearAll()

    /// Updates a banner alert state (show/hide).
    ///
    /// - Parameter banner: the banner alert to update
    func update(_ banner: BannerAlert, show: Bool)
}

// MARK: - Implementation

/// An implementation of the `BannerAlertManagerService` protocol.
class BannerAlertManagerServiceImpl {
    /// The banner alerts mode subject.
    private var modeSubject = CurrentValueSubject<BannerAlertMode, Never>(.full)
    /// The banner alerts subject.
    private var bannersSubject = CurrentValueSubject<[AnyBannerAlert], Never>([])
    /// The banner alerts container frame subject.
    private var containerSubject = CurrentValueSubject<CGRect, Never>(UIScreen.main.bounds)
    /// The cancellable tasks dictionary monitoring banner alerts on duration.
    private var onDurationTasks = [Int: AnyCancellable]()
    /// The cancellable tasks dictionary monitoring banner alerts snooze duration.
    private var snoozeTasks = [Int: AnyCancellable]()
    /// The banner alerts stack.
    private var bannersStack = [AnyBannerAlert]()

    // Convenience Properties

    /// The active banner alerts.
    private var activeBanners: [AnyBannerAlert] {
        // Filter out non-mandatory snoozed and queued banners.
        let alertBanners = bannersStack
            .filter { $0.severity != .mandatory }
            .filter { !snoozeTasks.keys.contains($0.uid) }
            .prefix(BannerAlertConstants.visibleBannerAlertsMaxCount)
        // Get mandatory banners.
        let mandatoryBanners = bannersStack
            .filter { $0.severity == .mandatory }

        return Array(mandatoryBanners) + Array(alertBanners)
    }
}

// MARK: `BannerAlertManagerService` protocol conformance
extension BannerAlertManagerServiceImpl: BannerAlertManagerService {

    var bannersModePublisher: AnyPublisher<BannerAlertMode, Never> { modeSubject.eraseToAnyPublisher() }
    var bannersPublisher: AnyPublisher<[AnyBannerAlert], Never> { bannersSubject.eraseToAnyPublisher() }
    var containerPublisher: AnyPublisher<CGRect, Never> { containerSubject.eraseToAnyPublisher() }

    func setMode(_ mode: BannerAlertMode) {
        modeSubject.value = mode
    }

    func setContainer(frame: CGRect) {
        containerSubject.value = frame
    }

    func show(_ banner: BannerAlert) {
        update(banner, show: true)
    }

    func hide(_ banner: BannerAlert) {
        update(banner, show: false)
    }

    func hide(_ banners: [BannerAlert]) {
        for banner in banners {
            hide(banner)
        }
    }

    func clearAll() {
        bannersSubject.value.removeAll()
        bannersStack.removeAll()
        for banner in onDurationTasks.keys {
            onDurationTasks[banner]?.cancel()
        }
        onDurationTasks.removeAll()
        for banner in snoozeTasks.keys {
            snoozeTasks[banner]?.cancel()
        }
        snoozeTasks.removeAll()
    }

    func update(_ banner: BannerAlert, show: Bool) {
        if show {
            add(AnyBannerAlert(banner))
        } else {
            remove(AnyBannerAlert(banner))
        }
    }
}

// MARK: Private functions
private extension BannerAlertManagerServiceImpl {
    /// Adds a banner alert to stack if not already present.
    ///
    /// - Parameter banner: the banner alert to add
    func add(_ banner: AnyBannerAlert) {
        guard !bannersStack.contains(banner) else {
            ULog.i(.tag, "Add \(banner) ignored, already present in \(bannersStack)")
            return
        }

        ULog.i(.tag, "Add \(banner)")
        bannersStack.sortedInsert(banner)
        publish()
    }

    /// Removes a banner alert from stack.
    ///
    /// - Parameter banner: the banner alert to remove
    func remove(_ banner: AnyBannerAlert) {
        guard bannersStack.contains(banner) else { return }

        if bannersSubject.value.contains(banner),
           let snoozeDuration = banner.behavior.snoozeDuration {
            snooze(banner, duration: snoozeDuration)
        }

        ULog.i(.tag, "Remove \(banner)")
        bannersStack.remove(banner)
        publish()
    }

    /// Snoozes a banner alert.
    ///
    /// - Parameters:
    ///    - banner: the banner alert to snooze
    ///    - duration: the snooze duration
    func snooze(_ banner: AnyBannerAlert, duration: TimeInterval) {
        // Exit if a snooze task is already in progress for this banner (should not be cumulated).
        guard snoozeTasks[banner.uid] == nil else { return }

        ULog.i(.tag, "Snooze \(banner) for \(duration)")

        snoozeTasks[banner.uid] = Just(true)
            .delay(for: .seconds(duration), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                ULog.i(.tag, "Snooze done for \(banner)")

                // Reset snooze task.
                self.snoozeTasks[banner.uid]?.cancel()
                self.snoozeTasks.removeValue(forKey: banner.uid)

                // Refresh alerts (awakened banner may be required on screen if still present in stack).
                self.publish()
            }
    }

    /// Publishes active banners to listeners.
    func publish() {
        guard activeBanners != bannersSubject.value else { return }

        bannersSubject.value = activeBanners

        ULog.i(.tag, "Active: \(bannersSubject.value), stack: \(bannersStack)")

        // Banner alerts can also be dismissed because of a higher severity alert addition.
        // => Ensure all ongoing on duration tasks are canceled for dismissed banner alerts.
        let dismissedBannerKeys = onDurationTasks.keys.filter { !bannersSubject.value.map({ $0.uid }).contains($0) }
        for key in dismissedBannerKeys {
            onDurationTasks[key]?.cancel()
            onDurationTasks.removeValue(forKey: key)
        }

        // Start on duration task for all active banner alerts.
        for banner in bannersSubject.value {
            if let onDuration = banner.behavior.onDuration,
               onDurationTasks[banner.uid] == nil {
                onDurationTasks[banner.uid] = Just(true)
                    .delay(for: .seconds(onDuration), scheduler: DispatchQueue.main)
                    .sink { [weak self] _ in
                        guard let self = self else { return }
                        ULog.i(.tag, "Duration elapsed for \(banner)")

                        // Reset task.
                        self.onDurationTasks[banner.uid]?.cancel()

                        if let snoozeDuration = banner.behavior.snoozeDuration {
                            self.snooze(banner, duration: snoozeDuration)
                        } else {
                            // Banner duration is elapsed, but no snooze duration is defined.
                            // => Need to remove it from stack.
                            self.bannersStack.remove(banner)
                        }

                        // Refresh alerts.
                        self.publish()
                    }
            }
        }
    }
}
