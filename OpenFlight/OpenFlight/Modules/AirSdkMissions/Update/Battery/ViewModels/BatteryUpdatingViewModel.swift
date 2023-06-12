//    Copyright (C) 2023 Parrot Drones SAS
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
    static let tag = ULogTag(name: "BatteryUpdatingViewModel")
}

/// Data for a cell in the updating process list.
struct BatteryUpdatingStep {
    var step: CurrentUpdatingStep
    var label: String
}

enum BatteryUpdateErrorType {
    case defaultError
    case serialChange
}

enum ProgressStep {
    case preparingUpdate(progress: Float)
    case updating
    case rebooting
    case error(_ error: BatteryUpdateErrorType)
    case success
}

/// Model for the `BatteryUpdatingViewController` class.
///
/// The battery gauge update has the following steps:
/// - when state is ready to prepare, send prepare command
/// - state becomes preparing update
/// - when state becomes ready to update, send update command
/// - state becomes updating
/// - when the update is done, the drone reboots automatically, wait for its reconnection
class BatteryUpdatingViewModel {
    // MARK: - Private Enum
    private enum Constants {
        static let minProgress: Float = 0.0
    }

    /// Enumeration of the rows displayed for the update process.
    private enum Elements: Int {
        case prepare = 0
        case update = 1
        case reboot = 2
    }

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    ///  `true` if a drone is connected.
    private var isDroneConnected: Bool = false
    /// `true` when the update command is sent.
    private var isUpdating = false
    /// Becomes `true` when the rebooting step is reached.
    private var isRebooting = false
    /// Becomes `true` when any error happens.
    private var hasFailed = false
    /// Becomes `true` if a different battery was plugged.
    private var serialChanged = false
    /// Subject for the updating process datasource.
    private var elementsSubject = CurrentValueSubject<[BatteryUpdatingStep], Never>([])
    /// Battery gauge updater service.
    private var batteryGaugeUpdaterService: BatteryGaugeUpdaterService
    /// Battery serial number.
    private var batterySerial: String?
    /// Battery configuration date.
    private var batteryConfigurationDate: Date?
    /// Current progress from 0 to 100, used to udpate the progress view.
    @Published private(set) var currentProgress: Float = Constants.minProgress
    /// progress step, used to update the progress view.
    @Published private(set) var progressStep: ProgressStep = .preparingUpdate(progress: Constants.minProgress)

    /// Publisher for the updating process datasource.
    var elementsPublisher: AnyPublisher<[BatteryUpdatingStep], Never> {
        elementsSubject.eraseToAnyPublisher()
    }
    /// The updating process datasource, used to display and update the process list.
    var elements: [BatteryUpdatingStep] {
        get { elementsSubject.value }
        set { elementsSubject.value = newValue }
    }

    // MARK: - Init

    /// Constructor
    /// - Parameter batteryGaugeUpdaterService: the injected battery gauge updater service
    init(batteryGaugeUpdaterService: BatteryGaugeUpdaterService,
         connectedDroneHolder: ConnectedDroneHolder) {
        self.batteryGaugeUpdaterService = batteryGaugeUpdaterService
        initDatasource()
        listenBatteryUpdater()
        listenDroneConnection(connectedDroneHolder)
    }

    /// Sends the "prepare update" command.
    func startUpdateProcess() {
        batteryGaugeUpdaterService.prepareUpdate()
    }

    /// Inits the list of elements in the process list.
    private func initDatasource() {
        let prepareElement = BatteryUpdatingStep(step: .waiting, label: L10n.batteryUpdatePreparingUpdate)
        let updateElement = BatteryUpdatingStep(step: .waiting, label: L10n.batteryUpdateUpdating)
        let rebootElement = BatteryUpdatingStep(step: .waiting, label: L10n.batteryUpdateWaitingForReboot)

        elements = [prepareElement, updateElement, rebootElement]
    }

    /// Listens to the battery updater peripheral.
    private func listenBatteryUpdater() {
        batteryGaugeUpdaterService.statePublisher
            .combineLatest(batteryGaugeUpdaterService.currentProgressPublisher,
                           batteryGaugeUpdaterService.unavailabilityReasonsPublisher)
            .removeDuplicates { prev, current in
                prev.0 == current.0 && prev.1 == current.1 && prev.2 == current.2
            }
            .sink { [weak self] state, currentProgress, unavailabilityReasons in
                guard let self = self, let state = state else { return }
                ULog.i(.tag, """
                    listenBatteryUpdater state: \(state) progress: \(currentProgress),
                    unavailabilityReasons:\(unavailabilityReasons.map { return $0.description })
                """)
                self.updateProgress(state: state, currentProgress: currentProgress, unavailabilityReasons: unavailabilityReasons)
                self.updateList(state: state, unavailabilityReasons: unavailabilityReasons)
            }
            .store(in: &cancellables)
    }

    /// Listens to the connected drone holder.
    /// - Parameter connectedDroneHolder: the injected connected drone holder
    private func listenDroneConnection(_ connectedDroneHolder: ConnectedDroneHolder) {
        connectedDroneHolder.dronePublisher
            .sink { [weak self] drone in
                guard let self = self else { return }
                self.isDroneConnected = drone != nil
                ULog.i(.tag, "listenDroneConnection:\(self.isDroneConnected) isUpdating:\(self.isUpdating)")
                if !self.isDroneConnected {
                    if self.isUpdating {
                        // The drone was updating and the connection is lost. Start the rebooting step.
                        self.isUpdating = false
                        self.isRebooting = true
                        self.updateProgressForReboot()
                        self.updateListForReboot()
                    } else {
                        // The connection was lost during preparation, possibly because the battery was removed. Stop the procedure immediately.
                        self.progressStep = .error(.defaultError)
                    }
                } else {
                    let batteryInfo = drone?.getInstrument(Instruments.batteryInfo)
                    let configurationDate = batteryInfo?.batteryDescription?.configurationDate
                    ULog.i(.tag, "listenDroneConnection - on connection: "
                           + "isRebooting: \(self.isRebooting)"
                           + "previous date:\(String(describing: self.batteryConfigurationDate))"
                           + "new date:\(String(describing: configurationDate))")
                    if self.batterySerial != nil
                        && batteryInfo?.serial != nil
                        && self.batterySerial != batteryInfo?.serial {
                        // The battery serial has changed: the battery has been replaced.
                        self.serialChanged = true
                        self.updateProgressForReboot()
                        self.updateListForReboot()
                        return
                    }
                    self.batterySerial = batteryInfo?.serial

                    if self.isRebooting {
                        // The drone is reconnected after rebooting.
                        // Check if configuration date has changed.
                        if self.batteryConfigurationDate != nil
                            && configurationDate != nil
                            && self.batteryConfigurationDate == configurationDate {
                            // Same date means no update.
                            self.progressStep = .error(.defaultError)
                            return
                        }
                        self.updateProgressForReboot()
                        self.updateListForReboot()
                    }
                    self.batteryConfigurationDate = configurationDate
                }
            }
            .store(in: &cancellables)
    }

    /// Updates the state list according the the peripheral feedback.
    ///
    /// Also starts the update step when the prepare step is complete.
    /// - Parameters:
    ///   - state: the current battery gauge updater state given by the peripheral
    ///   - unavailabilityReasons: the set of current unavailability reasons (e.g. USB unplugged)
    private func updateList(state: BatteryGaugeUpdaterState, unavailabilityReasons: Set<BatteryGaugeUpdaterUnavailabilityReasons>) {
        var prepareElement = elements[Elements.prepare.rawValue]
        var updateElement = elements[Elements.update.rawValue]
        var rebootElement = elements[Elements.reboot.rawValue]

        if !isRebooting && !hasFailed {
            switch state {
            case .readyToPrepare:
                    // really in the prepare step
                prepareElement.step = unavailabilityReasons.isEmpty ? .loading : .failed("")
                updateElement.step = .waiting
                rebootElement.step = .waiting
            case .preparingUpdate:
                prepareElement.step = unavailabilityReasons.isEmpty ? .loading : .failed("")
                updateElement.step = .waiting
                rebootElement.step = .waiting
            case .readyToUpdate:
                prepareElement.step = .succeeded
                if !isUpdating {
                    // Send the update commmand
                    batteryGaugeUpdaterService.update()
                    isUpdating = true
                }
            case .updating:
                prepareElement.step = .succeeded
                updateElement.step = unavailabilityReasons.isEmpty ? .loading : .failed("")
                rebootElement.step = .waiting
            case .error:
                if prepareElement.step != .succeeded {
                    prepareElement.step = .failed("") // handle error
                } else if updateElement.step != .succeeded {
                    updateElement.step = .failed("")
                } else {
                    rebootElement.step = .failed("")
                }
                hasFailed = true
            }
        }
        elements = [prepareElement, updateElement, rebootElement]
    }

    /// Updates the progress step during the update.
    ///
    /// The progress step wil be used by the controller to update the progress view and display error or success messages.
    /// - Parameters:
    ///   - state: the current battery gauge updater state
    ///   - currentProgress: the current progress (only used during preparing step)
    ///   - unavailabilityReasons: the set of current unavailability reasons (e.g. USB unplugged)
    func updateProgress(state: BatteryGaugeUpdaterState, currentProgress: UInt, unavailabilityReasons: Set<BatteryGaugeUpdaterUnavailabilityReasons>) {
        guard unavailabilityReasons.isEmpty else {
            self.progressStep = .error(.defaultError)
            return
        }
        switch state {
        case .readyToPrepare:
            self.progressStep = .preparingUpdate(progress: Constants.minProgress)
        case .preparingUpdate:
            self.progressStep = .preparingUpdate(progress: Float(currentProgress))
        case .readyToUpdate, .updating:
            self.progressStep = .updating
        case .error:
            self.progressStep = .error(.defaultError)
        }
    }

    /// Updates the step list during the reboot phase.
    func updateListForReboot() {
        let prepareElement = elements[Elements.prepare.rawValue]
        var updateElement = elements[Elements.update.rawValue]
        var rebootElement = elements[Elements.reboot.rawValue]
        if isDroneConnected {
            if serialChanged {
                updateElement.step = .failed("")
                rebootElement.step = .succeeded
            } else {
                updateElement.step = .succeeded
                rebootElement.step = .succeeded
            }
        } else {
            updateElement.step = .succeeded
            rebootElement.step = .loading
        }
        elements = [prepareElement, updateElement, rebootElement]
    }

    /// Updates the progress step during the reboot phase.
    func updateProgressForReboot() {
        if serialChanged {
            self.progressStep = .error(.serialChange)
            return
        }
        if isRebooting && isDroneConnected {
            // reboot ended
            self.progressStep = .success
        } else {
            // reboot ongoing
            self.progressStep = .rebooting
        }
    }
}
