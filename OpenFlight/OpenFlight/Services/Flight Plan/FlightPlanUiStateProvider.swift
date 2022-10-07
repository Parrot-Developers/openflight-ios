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

import Combine

public struct FlightPlanStateUiParameters {

    public typealias ButtonAction = ((Coordinator?) -> Void)

    public init(statusText: String? = nil,
                statusTextColor: Color? = nil,
                uploadingPhotosCount: Int? = nil,
                uploadingExtraIcon: UIImage? = nil,
                uploadingProgressText: String? = nil,
                uploadPausedText: String? = nil,
                uploadPausedTextColor: Color? = nil,
                uploadPausedProgressText: String? = nil,
                freemiumText: String? = nil,
                actionButtonIcon: UIImage? = nil,
                actionButtonText: String? = nil,
                actionButtonTextColor: UIColor? = nil,
                actionButtonColor: UIColor? = nil,
                actionButtonProgress: Double? = nil,
                actionButtonProgressColor: UIColor? = nil,
                isActionButtonEnabled: Bool? = true,
                actionButtonCallback: ButtonAction? = nil,
                historyStatusText: String? = nil,
                historyStatusTextColor: Color? = nil,
                historyExtraIcon: UIImage? = nil,
                historyExtraIconColor: Color? = nil) {
        self.statusText = statusText
        self.statusTextColor = statusTextColor
        self.uploadingPhotosCount = uploadingPhotosCount
        self.uploadingExtraIcon = uploadingExtraIcon
        self.uploadingProgressText = uploadingProgressText
        self.uploadPausedText = uploadPausedText
        self.uploadPausedTextColor = uploadPausedTextColor
        self.uploadPausedProgressText = uploadPausedProgressText
        self.freemiumText = freemiumText
        self.actionButtonIcon = actionButtonIcon
        self.actionButtonText = actionButtonText
        self.actionButtonTextColor = actionButtonTextColor
        self.actionButtonColor = actionButtonColor
        self.actionButtonProgress = actionButtonProgress
        self.actionButtonProgressColor = actionButtonProgressColor
        self.isActionButtonEnabled = isActionButtonEnabled
        self.historyStatusText = historyStatusText
        self.historyStatusTextColor = historyStatusTextColor
        self.historyExtraIcon = historyExtraIcon
        self.historyExtraIconColor = historyExtraIconColor
        self.actionButtonCallback = actionButtonCallback
    }

    // ----
    // FP/PGY Details view
    // ----

    // FlightPlan completion Status
    public var statusText: String?
    public var statusTextColor: Color?

    // Pix4D upload
    // Uploading Photo State
    public var uploadingPhotosCount: Int?
    public var uploadingExtraIcon: UIImage?
    public var uploadingProgressText: String?
    // Uploading Photo State
    public var uploadPausedText: String?
    public var uploadPausedTextColor: Color?
    public var uploadPausedProgressText: String?

    // freemium account info
    public var freemiumText: String?

    // Action Button (used in FP Details view)
    public var actionButtonIcon: UIImage?
    public var actionButtonText: String?
    public var actionButtonTextColor: UIColor?
    public var actionButtonColor: UIColor?
    public var actionButtonProgress: Double?
    public var actionButtonProgressColor: UIColor?
    public var actionButtonAction: ButtonAction?
    public var actionButtonCallback: ((Coordinator?) -> Void)?
    public var isActionButtonEnabled: Bool?

    // ----
    // FP/PGY History cells
    // ----

    public var historyStatusText: String?
    public var historyStatusTextColor: Color?
    public var historyExtraIcon: UIImage?
    public var historyExtraIconColor: Color?
}

public protocol FlightPlanOptionalUiStateProvider {
    func uiState(for flightPlan: FlightPlanModel) -> FlightPlanStateUiParameters?
    func uiStatePublisher(for flightPlan: FlightPlanModel) -> AnyPublisher<FlightPlanStateUiParameters?, Never>
}

public protocol FlightPlanUiStateProvider {
    func add(optionalProvider: FlightPlanOptionalUiStateProvider)
    func uiState(for flightPlan: FlightPlanModel) -> FlightPlanStateUiParameters
    func uiStatePublisher(for flightPlan: FlightPlanModel) -> AnyPublisher<FlightPlanStateUiParameters, Never>
}

public class FlightPlanUiStateProviderImpl {
    private var optionalProviders = [FlightPlanOptionalUiStateProvider]()
    private let stateMachine: FlightPlanStateMachine
    private let projectManager: ProjectManager
    private let startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher

    init(stateMachine: FlightPlanStateMachine,
         startAvailabilityWatcher: FlightPlanStartAvailabilityWatcher,
         projectManager: ProjectManager) {
        self.stateMachine = stateMachine
        self.startAvailabilityWatcher = startAvailabilityWatcher
        self.projectManager = projectManager
    }
}

extension FlightPlanUiStateProviderImpl: FlightPlanUiStateProvider {

    public func add(optionalProvider: FlightPlanOptionalUiStateProvider) {
        optionalProviders.append(optionalProvider)
    }

    public func uiState(for flightPlan: FlightPlanModel) -> FlightPlanStateUiParameters {
        if let result = optionalProviders.lazy.compactMap({ $0.uiState(for: flightPlan) }).first {
            return result
        }

        let state = flightPlan.state
        let isActionButtonEnabled = state.isButtonEnabled(startAvailability: startAvailabilityWatcher.availabilityForSendingMavlink)

        return FlightPlanStateUiParameters(statusText: state.labelText(for: flightPlan),
                                           statusTextColor: state.labelColor,
                                           actionButtonIcon: state.buttonIcon,
                                           actionButtonText: state.buttonText,
                                           actionButtonTextColor: state.buttonTextColor,
                                           actionButtonColor: state.buttonColor,
                                           isActionButtonEnabled: isActionButtonEnabled,
                                           actionButtonCallback: buttonAction(for: flightPlan),
                                           historyStatusText: state.historyStatusText(for: flightPlan),
                                           historyStatusTextColor: state.historyStatusTextColor)
    }

    public func uiStatePublisher(for flightPlan: FlightPlanModel) -> AnyPublisher<FlightPlanStateUiParameters, Never> {
        let smPublisher = stateMachine.currentFlightPlanPublisher
            .compactMap { $0?.uuid == flightPlan.uuid ? $0 : nil }
        var statePublisher = Just(flightPlan)
            .merge(with: smPublisher)
            .map { [unowned self] in uiState(for: $0) }
            .eraseToAnyPublisher()
        for provider in optionalProviders {
            let providerPublisher = provider.uiStatePublisher(for: flightPlan)
                .compactMap { $0 }
            statePublisher = statePublisher
                .merge(with: providerPublisher)
                .eraseToAnyPublisher()
        }
        return statePublisher
    }
}

extension FlightPlanUiStateProviderImpl {

    typealias ButtonAction = FlightPlanStateUiParameters.ButtonAction

    func resumeFlight(for flightPlan: FlightPlanModel, coordinator: Coordinator?) {
        guard let coordinator = coordinator as? FlightPlanExecutionDetailsCoordinator else { return }
        coordinator.open(flightPlan: flightPlan)
    }

    func buttonAction(for flightPlan: FlightPlanModel) -> ButtonAction? {
        guard [.stopped, .flying].contains(flightPlan.state) else { return nil }
        let buttonAction: ButtonAction = { [unowned self] coordinator in
            resumeFlight(for: flightPlan, coordinator: coordinator)
        }
        return buttonAction
    }
}

// MARK: - FlightPlanStateUiParameters
private extension FlightPlanModel.FlightPlanState {

    func labelText(for flightPlan: FlightPlanModel) -> String? {
        switch self {
        case .stopped:
            // clamp value so that 99.nn is not displayed as 100
            return L10n.flightPlanAlertStoppedAt((0.0 ... 99.49).clamp(flightPlan.percentCompleted).asPercent(maximumFractionDigits: 0))
        case .flying:
            return L10n.flightPlanAlertStoppedAt(flightPlan.percentCompleted.asPercent(maximumFractionDigits: 0))
        case .completed:
            return L10n.flightPlanRunCompleted
        // If we falling back here when state = .uploading, we handle it as "completed"
        case .uploading:
            return L10n.flightPlanRunCompleted
        default:
            return nil
        }
    }

    var labelColor: Color? {
        switch self {
        case .stopped, .flying:
            return ColorName.warningColor.color
        case .completed:
            return ColorName.highlightColor.color
        // If we falling back here when state = .uploading, we handle it as "completed"
        case .uploading:
            return ColorName.highlightColor.color
        default:
            return nil
        }
    }

    var buttonIcon: UIImage? {
        switch self {
        case .stopped, .flying:
            return Asset.Common.Icons.icResume.image
        default:
            return nil
        }
    }

    var buttonText: String? {
        switch self {
        case .stopped, .flying:
            return L10n.flightPlanDetailsResumeFlightButtonTitle
        default:
            return nil
        }
    }

    var buttonTextColor: Color? {
        switch self {
        case .stopped, .flying:
            return ColorName.white.color
        default:
            return nil
        }
    }

    var buttonColor: Color? {
        switch self {
        case .stopped, .flying:
            return ColorName.highlightColor.color
        default:
            return nil
        }
    }

    /// Returns FP UI action button isEnabled state according to FP start availability.
    ///
    /// - Parameter startAvailability: the FP start availability
    /// - Returns: `true` if the action button is enabled, `false` otherwise
    func isButtonEnabled(startAvailability: FlightPlanStartAvailability) -> Bool {
        if case .unavailable = startAvailability {
            // FP cannot be started => action button is disabled.
            return false
        }
        return true
    }

    func historyStatusText(for flightPlan: FlightPlanModel) -> String? {
        switch self {
        case .stopped:
            // clamp value so that 99.nn is not displayed as 100
            return L10n.flightPlanHistoryExecutionIncompleteAtDescription((0.0 ... 99.49).clamp(flightPlan.percentCompleted).asPercent(maximumFractionDigits: 0))
        case .flying:
            return L10n.flightPlanHistoryExecutionIncompleteAtDescription(flightPlan.percentCompleted.asPercent(maximumFractionDigits: 0))
        case .completed:
            return L10n.flightPlanHistoryExecutionCompletedDescription
        // If we falling back here when state = .uploading, we handle it as "completed"
        case .uploading:
            return L10n.flightPlanHistoryExecutionCompletedDescription
        default:
            return nil
        }
    }

    var historyStatusTextColor: Color? {
        switch self {
        case .stopped, .flying:
            return ColorName.warningColor.color
        case .completed:
            return ColorName.highlightColor.color
        // If we falling back here when state = .uploading, we handle it as "completed"
        case .uploading:
            return ColorName.highlightColor.color
        default:
            return nil
        }
    }
}
