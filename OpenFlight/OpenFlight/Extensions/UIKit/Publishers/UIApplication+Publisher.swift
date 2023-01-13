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

import Foundation
import Combine

// MARK: - App States

/// An `UIApplication` extension dedicated to publish App state changes.
public extension UIApplication {

    /// App states enum.
    enum AppState {
        case willEnterForeground
        case didBecomeActive
        case didEnterBackground
        case willResignActive
        case willTerminate
    }

    /// Publisher informing about App state changes.
    static var statePublisher: AnyPublisher<AppState, Never> {
        Publishers.MergeMany(
            NotificationCenter.default
                .publisher(for: UIApplication.willEnterForegroundNotification)
                .map { _ in .willEnterForeground },
            NotificationCenter.default
                .publisher(for: UIApplication.didBecomeActiveNotification)
                .map { _ in .didBecomeActive },
            NotificationCenter.default
                .publisher(for: UIApplication.didEnterBackgroundNotification)
                .map { _ in .didEnterBackground },
            NotificationCenter.default
                .publisher(for: UIApplication.willResignActiveNotification)
                .map { _ in .willResignActive },
            NotificationCenter.default
                .publisher(for: UIApplication.willTerminateNotification)
                .map { _ in .willTerminate }
        ).eraseToAnyPublisher()
    }
}

// MARK: - Memory Pressure

/// - Note: This is the safest way to be informed about low memory issues, with the ability to distingish the severity
///         of the memory pressure, while some delegate methods, such `applicationDidReceiveMemoryWarning(_)`,
///         can, in certain circonstances (e.g. consumming loop without leting the system calling the delegate method before the crash),
///         not be called when they should.
///
///      *Examples of use:*
///         ```
///            UIApplication.memoryPressurePublisher
///            .sink { print("Memory Pressure changed: '\($0)'") }
///            .store(in: &cancellables)
///         ```
///         ```
///            UIApplication.memoryPressurePublisher(eventMask: [.critical, .warning])
///            .sink { print("'\($0)' Memory Pressure: Please free up the memory!") }
///            .store(in: &cancellables)
///         ```

/// The memory pressure publisher.
public struct MemoryPressurePublisher: Publisher {
    public typealias Output = DispatchSource.MemoryPressureEvent
    public typealias Failure = Never

    let eventMask: DispatchSource.MemoryPressureEvent

    init(eventMask: DispatchSource.MemoryPressureEvent = .all) {
        self.eventMask = eventMask
    }

    public func receive<S: Subscriber>(subscriber: S) where
    S.Input == Output,
    S.Failure == Failure {
        let subscription = MemoryPressureSubscription(subscriber: subscriber,
                                                      eventMask: eventMask)
        subscriber.receive(subscription: subscription)
    }
}

/// The memory pressure subscription.
private class MemoryPressureSubscription<S: Subscriber>: Subscription where
S.Input == DispatchSource.MemoryPressureEvent {

    private var subscriber: S?
    private let dispatchSource: DispatchSourceMemoryPressure

    init(subscriber: S, eventMask: DispatchSource.MemoryPressureEvent) {
        self.subscriber = subscriber
        self.dispatchSource = DispatchSource.makeMemoryPressureSource(eventMask: eventMask)
        configure()
    }

    private func configure() {
        dispatchSource.setEventHandler { [weak self] in
            // Ensure the DispatchSource has not been cancelled before publishing the event.
            guard let self = self,
                  !self.dispatchSource.isCancelled
            else { return }
            _ = self.subscriber?.receive(self.dispatchSource.data)
        }
    }

    func request(_ demand: Subscribers.Demand) {
        dispatchSource.activate()
    }

    func cancel() {
        dispatchSource.cancel()
        subscriber = nil
    }
}

/// Adding Memory Pressure Publisher to UIApplication
public extension UIApplication {
    /// A publisher intended to listen all memory pressure events.
    static var memoryPressurePublisher: MemoryPressurePublisher { MemoryPressurePublisher() }

    /// A publisher intented to listen only specific types of event.
    ///
    /// - Parameter eventMask: the event mask applied
    ///
    /// - Description: In contrary of `memoryPressurePublisher`, this publisher allows to be 'called' only for
    ///                events specified in parameters.
    ///                Example: `UIApplication.memoryPressurePublisher(eventMask: [.critical, .warning])`
    static func memoryPressurePublisher(eventMask: DispatchSource.MemoryPressureEvent)
    -> MemoryPressurePublisher {
        MemoryPressurePublisher(eventMask: eventMask)
    }
}

/// Memory Pressure Event Custom String.
extension DispatchSource.MemoryPressureEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .normal: return ".normal"
        case .warning: return ".warning"
        case .critical: return ".critical"
        case .all: return ".all"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Disk Space

/// An `UIApplication` extension dedicated to publish Low Disk Space events.
public extension UIApplication {

    /// Publisher informing about Low Disk Space Events.
    static var lowDiskSpacePublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: .NSBundleResourceRequestLowDiskSpace)
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
