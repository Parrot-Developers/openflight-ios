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

import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "UserStorageService")
}

/// A user storage state.
public enum UserStorageState {

    case available, notDetected, needsFormat, unknown

    /// Whether user storage is detected.
    var isDetected: Bool { self == .available || self == .needsFormat }
    /// Whether user storage has errors.
    var hasError: Bool { self == .needsFormat || self == .notDetected }
}

/// A reason for the unavailability of the storage formatting.
public enum StorageFormattingUnavailabilityReason: Equatable {

    /// Storage does not support formatting.
    case notSupported
    /// Drone is flying.
    case droneIsFlying

    /// The information message to display describing the unavailability reason.
    var message: String? {
        switch self {
        case .droneIsFlying:
            return L10n.galleryMediaFormatSdCardLandDroneInstructions
        case .notSupported:
            return nil
        }
    }
}

/// A state describing the formatting availability and status.
public enum StorageFormattingState: Equatable {

    /// State is unknown.
    case unknown
    /// Formatting is available and running if `status` is not `nil`.
    case available(_ status: FormattingState?)
    /// Formatting is unavailable for a specific reason.
    case unavailable(_ reason: StorageFormattingUnavailabilityReason)

    // MARK: Convenience computed properties
    /// Whether formatting is complete.
    var isComplete: Bool {
        if case .available(let formattingState) = self {
            return formattingState?.step == .creatingFs && formattingState?.progress == 100
        }
        return false
    }

    /// Whether formatting is running.
    var isRunning: Bool {
        if case .available(let formattingState) = self {
            return formattingState != nil
        }
        return false
    }
}

// MARK: - Protocol

/// The protocol defining the user storage service.
public protocol UserStorageService: AnyObject {

    /// The removable storage details.
    var removableStorageDetails: UserStorageDetails { get }
    /// The internal storage details.
    var internalStorageDetails: UserStorageDetails { get }
    /// The publisher for removable storage details.
    var removableStorageDetailsPublisher: AnyPublisher<UserStorageDetails, Never> { get }
    /// The publisher for internal storage details.
    var internalStorageDetailsPublisher: AnyPublisher<UserStorageDetails, Never> { get }
    /// The publisher for removable storage state.
    var removableStorageStatePublisher: AnyPublisher<UserStorageState, Never> { get }
    /// The publisher for formatting state.
    var formattingStatePublisher: AnyPublisher<StorageFormattingState, Never> { get }

    /// Requests a format of the removable storage.
    ///
    /// - Parameter formattingType: the formatting type
    /// - Returns: `true` if the format has been actually asked to the peripheral, `false` otherwise
    func format(formattingType: FormattingType) -> Bool

    /// Returns the storage details for a specific source type.
    ///
    /// - Parameter source: the source type to get the details from
    /// - Returns: the source's storage details
    func storageDetails(for source: GallerySourceType) -> UserStorageDetails
}

// MARK: - Implementation

/// An implementation of the `UserStorageService` protocol.
public class UserStorageServiceImpl {

    /// The cancellables.
    private var cancellables = Set<AnyCancellable>()
    /// The drone state reference.
    private var droneStateRef: Ref<DeviceState>?
    /// The flying indicators reference.
    private var flyingIndicatorRef: Ref<FlyingIndicators>?
    /// The removable storage reference.
    private var removableStorageRef: Ref<RemovableUserStorage>?
    /// The internal storage reference.
    private var internalStorageRef: Ref<InternalUserStorage>?
    /// The removable storage details subject.
    private var removableStorageDetailsSubject = CurrentValueSubject<UserStorageDetails, Never>(UserStorageDetails())
    /// The internal storage details subject.
    private var internalStorageDetailsSubject = CurrentValueSubject<UserStorageDetails, Never>(UserStorageDetails())
    /// The removable storage state subject.
    private var removableStorageStateSubject = CurrentValueSubject<UserStorageState, Never>(.unknown)
    /// The publisher for formatting state.
    private var formattingStateSubject = CurrentValueSubject<StorageFormattingState, Never>(.unknown)

    /// Whether the drone is flying.
    private var isDroneFlying = false {
        didSet {
            guard oldValue != isDroneFlying else { return }
            updateFormattingState()
        }
    }

    /// Whether the active storage can be formatted.
    private var isFormattingSupported = false {
        didSet {
            guard oldValue != isFormattingSupported else { return }
            updateFormattingState()
        }
    }

    /// The ongoing formatting process status (if any).
    private var formattingStatus: FormattingState? {
        didSet { updateFormattingState() }
    }

    // MARK: Init
    /// Constructor.
    ///
    /// - Parameters:
    ///   - currentDroneHolder: drone holder
    init(currentDroneHolder: CurrentDroneHolder) {
        listenTo(currentDroneHolder)
    }
}

// MARK: UserStorageService protocol conformance
extension UserStorageServiceImpl: UserStorageService {

    /// The removable storage details.
    public var removableStorageDetails: UserStorageDetails { removableStorageDetailsSubject.value }
    /// The internal storage details.
    public var internalStorageDetails: UserStorageDetails { internalStorageDetailsSubject.value }
    /// The publisher for removable storage details.
    public var removableStorageDetailsPublisher: AnyPublisher<UserStorageDetails, Never> { removableStorageDetailsSubject.eraseToAnyPublisher() }
    /// The publisher for internal storage details.
    public var internalStorageDetailsPublisher: AnyPublisher<UserStorageDetails, Never> { internalStorageDetailsSubject.eraseToAnyPublisher() }
    /// The publisher for removable storage state.
    public var removableStorageStatePublisher: AnyPublisher<UserStorageState, Never> { removableStorageStateSubject.eraseToAnyPublisher() }
    /// The publisher for formatting state.
    public var formattingStatePublisher: AnyPublisher<StorageFormattingState, Never> { formattingStateSubject.eraseToAnyPublisher() }

    /// Requests a format of the removable storage.
    ///
    /// - Parameter formattingType: the formatting type
    /// - Returns: `true` if the format has been actually asked to the peripheral, `false` otherwise
    public func format(formattingType: FormattingType) -> Bool {
        guard let storage = removableStorageRef?.value else { return false }
        return storage.format(formattingType: formattingType)
    }

    /// Returns the storage details for a specific source type.
    ///
    /// - Parameter source: the source type to get the details from
    /// - Returns: the source's storage details
    public func storageDetails(for source: GallerySourceType) -> UserStorageDetails {
        switch source {
        case .droneSdCard:
            return removableStorageDetails
        case .droneInternal:
            return internalStorageDetails
        case .mobileDevice:
            let capacity = UIDevice.current.capacityAsDouble
            let storageUsed = max(0, capacity - UIDevice.current.availableSpaceAsDouble)
            return .init(type: .mobileDevice,
                         storageUsed: storageUsed,
                         storageCapacity: capacity)
        default:
            return .init()
        }
    }
}

// Peripherals and intruments listeners.
private extension UserStorageServiceImpl {

    /// Listens to current drone holder.
    ///
    /// - Parameter currentDroneHolder: the current drone holder
    func listenTo(_ currentDroneHolder: CurrentDroneHolder) {
        currentDroneHolder.dronePublisher
            .sink { [unowned self] drone in
                // Listen to required intruments and peripherals.
                listenToDroneState(drone: drone)
                listenToFlyingIndicators(drone: drone)
                listenToRemovableUserStorage(drone: drone)
                listenToInternalUserStorage(drone: drone)
            }
            .store(in: &cancellables)
    }

    /// Listens to drone's state.
    ///
    /// - Parameter drone: the current drone
    func listenToDroneState(drone: Drone) {
        droneStateRef = drone.getState { [weak self] state in
            self?.updateStorageState(droneState: state)
        }
    }

    /// Listens to drone's flying indicators.
    /// Needed in order to update formatting capability accordingly.
    ///
    /// - Parameter drone: the current drone
    func listenToFlyingIndicators(drone: Drone) {
        flyingIndicatorRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.isDroneFlying = drone.isFlying
        }
    }

    /// Listens to removable user storage.
    ///
    /// - Parameter drone: the current drone
    func listenToRemovableUserStorage(drone: Drone) {
        removableStorageRef = drone.getPeripheral(Peripherals.removableUserStorage) { [weak self] storage in
            self?.updateRemovableStorage(storage: storage)
        }
    }

    /// Listens to internal user storage.
    ///
    /// - Parameter drone: the current drone
    func listenToInternalUserStorage(drone: Drone) {
        internalStorageRef = drone.getPeripheral(Peripherals.internalUserStorage) { [weak self] storage in
            self?.updateInternalStorage(storage: storage)
        }
    }
}

private extension UserStorageServiceImpl {

    /// Updates storage details according to drone's connection state.
    ///
    /// - Parameter droneState: the drone's state
    func updateStorageState(droneState: DeviceState?) {
        if droneState?.connectionState == .disconnected {
            resetRemovableStorageInfo()
        }
    }

    /// Updates removable storage details according to provided state.
    ///
    /// - Parameter storage: the removable storage state
    func updateRemovableStorage(storage: RemovableUserStorage?) {
        guard let storage = storage else {
            resetRemovableStorageInfo()
            return
        }
        ULog.i(.tag, "[galleryRework] RemovableUserStorage state \(storage.state) | details \(storage.sourceDetails)")
        removableStorageStateSubject.value = storage.state
        removableStorageDetailsSubject.value = storage.sourceDetails
        isFormattingSupported = storage.canFormat
        formattingStatus = storage.formattingState
    }

    /// Resets removable storage information.
    func resetRemovableStorageInfo() {
        removableStorageStateSubject.value = .unknown
        removableStorageDetailsSubject.value = .init(type: .droneSdCard, isOffline: true)
        formattingStateSubject.value = .unknown
    }

    /// Updates internal storage details according to provided state.
    ///
    /// - Parameter storage: the internal storage state
    func updateInternalStorage(storage: InternalUserStorage?) {
        guard let storage = storage else { return }
        internalStorageDetailsSubject.value = storage.sourceDetails
    }

    /// Updates formatting state according to current conditions.
    func updateFormattingState() {
        if isDroneFlying {
            formattingStateSubject.value = .unavailable(.droneIsFlying)
        } else if !isFormattingSupported && formattingStatus == nil {
            // SDK reports `!canFormat` during a formatting process
            // => set state to `.notSupported` only if no formatting is ongoing.
            formattingStateSubject.value = .unavailable(.notSupported)
        } else {
            formattingStateSubject.value = .available(formattingStatus)
        }
    }
}

// MARK: - Extensions

extension UserStorage {

    /// The user storage global state according to its physical and file system states.
    var state: UserStorageState {
        switch (physicalState, fileSystemState) {
        case (.noMedia, _):
            return .notDetected
        case (.available, _):
            return fileSystemState == .needFormat ? .needsFormat : fileSystemState == .ready ? .available : .unknown
        default:
            return .unknown
        }
    }

    /// The space used (in Go).
    var storageUsed: Double? {
        guard let mediaInfo = mediaInfo, availableSpace > 0 else { return nil }
        return max(0, Double((mediaInfo.capacity) - availableSpace)) / Double(StorageUtils.Constants.bytesPerGigabyte)
    }

    /// The storage capacity (in Go).
    var storageCapacity: Double? {
        guard let capacity = mediaInfo?.capacity, capacity != 0 else { return nil }
        return Double(capacity) / Double(StorageUtils.Constants.bytesPerGigabyte)
    }
}

extension RemovableUserStorage {

    /// The removable storage details according to its current state.
    var sourceDetails: UserStorageDetails {
        .init(type: .droneSdCard,
              storageUsed: storageUsed,
              storageCapacity: storageCapacity)
    }
}

extension InternalUserStorage {

    /// The internal storage details according to its current state.
    var sourceDetails: UserStorageDetails {
        .init(type: .droneInternal,
              storageUsed: storageUsed,
              storageCapacity: storageCapacity)
    }
}
