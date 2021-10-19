//
//  Copyright (C) 2021 Parrot Drones SAS.
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

    public enum ButtonAction {
        case resumeFlight, resumeUpload, openProjectWebView
    }

    public init(statusText: String? = nil,
                statusTextColor: Color? = nil,
                uploadingPhotosCount: Int? = nil,
                uploadingExtraIcon: UIImage? = nil,
                uploadingProgressText: String? = nil,
                uploadPausedText: String? = nil,
                uploadPausedProgressText: String? = nil,
                freemiumText: String? = nil,
                actionButtonText: String? = nil,
                actionButtonTextColor: UIColor? = nil,
                actionButtonColor: UIColor? = nil,
                actionButtonProgress: Double? = nil,
                actionButtonProgressColor: UIColor? = nil,
                actionButtonAction: ButtonAction? = nil,
                actionButtonCallback: ((Coordinator?) -> Void)? = nil,
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
        self.uploadPausedProgressText = uploadPausedProgressText
        self.freemiumText = freemiumText
        self.actionButtonText = actionButtonText
        self.actionButtonTextColor = actionButtonTextColor
        self.actionButtonColor = actionButtonColor
        self.actionButtonProgress = actionButtonProgress
        self.actionButtonProgressColor = actionButtonProgressColor
        self.actionButtonAction = actionButtonAction
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
    let statusText: String?
    let statusTextColor: Color?

    // Pix4D upload
    // Uploading Photo State
    var uploadingPhotosCount: Int?
    var uploadingExtraIcon: UIImage?
    var uploadingProgressText: String?
    // Uploading Photo State
    var uploadPausedText: String?
    var uploadPausedProgressText: String?

    // freemium account info
    var freemiumText: String?

    // Action Button (used in FP Details view)
    let actionButtonText: String?
    let actionButtonTextColor: UIColor?
    let actionButtonColor: UIColor?
    let actionButtonProgress: Double?
    let actionButtonProgressColor: UIColor?
    let actionButtonAction: ButtonAction?
    let actionButtonCallback: ((Coordinator?) -> Void)?

    // ----
    // FP/PGY History cells
    // ----

    let historyStatusText: String?
    let historyStatusTextColor: Color?
    let historyExtraIcon: UIImage?
    let historyExtraIconColor: Color?
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

    init(stateMachine: FlightPlanStateMachine,
         projectManager: ProjectManager) {
        self.stateMachine = stateMachine
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

        var buttonAction: ((Coordinator?) -> Void)?

        let state = flightPlan.state

        if case .resumeFlight = state.buttonAction {
            buttonAction = { [unowned self] coordinator in
                resumeFlight(for: flightPlan, coordinator: coordinator)
            }
        }

        return FlightPlanStateUiParameters(statusText: state.labelText(for: flightPlan),
                                           statusTextColor: state.labelColor,
                                           actionButtonText: state.buttonText,
                                           actionButtonTextColor: state.buttonTextColor,
                                           actionButtonColor: state.buttonColor,
                                           actionButtonCallback: buttonAction,
                                           historyStatusText: state.historyStatusText,
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

    func resumeFlight(for flightPlan: FlightPlanModel, coordinator: Coordinator?) {
        guard let coordinator = coordinator as? DashboardCoordinator else { return }
        coordinator.open(flightPlan: flightPlan)
    }
}

// MARK: - FlightPlanStateUiParameters
private extension FlightPlanModel.FlightPlanState {

    func labelText(for flightPlan: FlightPlanModel) -> String? {
        switch self {
        case .stopped, .flying:
            return L10n.flightPlanAlertStoppedAt(flightPlan.percentCompleted.asPercent())
        case .completed:
            return L10n.flightPlanRunCompleted
        // If we falling back here when state = .uplaoding, we handle it as "completed"
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
        // If we falling back here when state = .uplaoding, we handle it as "completed"
        case .uploading:
            return ColorName.highlightColor.color
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
            return ColorName.warningColor.color
        default:
            return nil
        }
    }

    var buttonAction: FlightPlanStateUiParameters.ButtonAction? {
        switch self {
        case .stopped, .flying:
            return .resumeFlight
        default:
            return nil
        }
    }

    var historyStatusText: String? {
        switch self {
        case .stopped, .flying:
            return L10n.flightPlanHistoryExecutionIncompleteDescription
        case .completed:
            return L10n.flightPlanHistoryExecutionCompletedDescription
        // If we falling back here when state = .uplaoding, we handle it as "completed"
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
        // If we falling back here when state = .uplaoding, we handle it as "completed"
        case .uploading:
            return ColorName.highlightColor.color
        default:
            return nil
        }
    }
}
