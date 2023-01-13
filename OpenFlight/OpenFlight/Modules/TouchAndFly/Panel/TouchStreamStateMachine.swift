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
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "TouchStreamStateMachine")
}

/// Events processed by the state machine.
public enum TouchStreamStateMachineEvent {
    case began(_ location: CGPoint)
    case moved(_ location: CGPoint)
    case ended(_ location: CGPoint)
    case cancelled
    case updated(_ element: StreamElement)
    case runningStateUpdated(_ state: TouchAndFlyRunningState)
}

/// States of the state machine.
private enum TouchStreamStateMachineState {
    /// No active stream element.
    case empty
    /// Touch started to add a new element.
    case dragNew
    /// Active element is a waypoint.
    case waypoint
    /// Currently dragging a waypoint.
    case dragWaypoint
    /// Active element is a poi.
    case poi
    /// Currently on a long tap.
    case longTap
    /// Currently dragging a poi.
    case dragPoi
}

private enum Constants {
    static let outsideCircle = 42.0
    static let diamondSize = 54.0
    static let dragMinimumOffset = 5.0
    static let altitudeOffsetRatio = 15.0
    static let longTapDelay = 0.5
    static let minimumVisibleDistance = 3.0
}

protocol TouchStreamStateMachineView {
    func pointInStreamView(point: CGPoint) -> CGPoint
    func clear()
    func clearWayPoint()
    func clearPoi()
    func createWaypoint(altitude: Double)
    func createPoi(altitude: Double)
    func createArrows(dragDirection: TouchStreamView.DragDirection)
    func updateArrows(location: CGPoint, dragDirection: TouchStreamView.DragDirection)
    func clearArrows()
    func createAxisIfNeeded(location: CGPoint, dragDirection: TouchStreamView.DragDirection)
    func clearAxis()
    func updateGraphic(type: TouchStreamView.TypeView, size: Double, location: CGPoint)
    func updateUser(location: CGPoint)
    func clampedLocation(location: CGPoint, objectSize: Double) -> CGPoint
    func saveWaypointLocation(_ location: CGPoint, dragDirection: TouchStreamView.DragDirection) -> Bool
    func savePoiLocation(_ location: CGPoint) -> Bool
}

/// State machine for the touch stream view.
class TouchStreamStateMachine {
    /// The view linked to the state machine
    private var view: TouchStreamStateMachineView
    /// The current state of the state machine
    private var currentState: TouchStreamStateMachineState {
        didSet {
            if oldValue != currentState {
                ULog.d(.tag, "state changed from \(oldValue) to \(currentState)")
            }
        }
    }
    /// The drag direction used for waypoint updates
    private var dragDirection: TouchStreamView.DragDirection = .undefined
    /// The original drag point used for waypoint updates
    private var originalDragPoint: CGPoint?
    /// The start time of a tap, used to detect a long tap
    private var startTime: Date?
    /// The location of a newly created poi after a long tap
    private var newPoiLocation: CGPoint?

    /// Required init.
    ///
    /// - Parameters:
    ///   - view: the touch stream view using the state machine
    required init(view: TouchStreamStateMachineView) {
        self.view = view
        self.currentState = .empty
    }

    /// Resets the state machine.
    func reset() {
        currentState = .empty
        dragDirection = .undefined
        originalDragPoint = nil
        startTime = nil
        newPoiLocation = nil
    }

    /// Processes an event and updates the state of the machine.
    ///
    /// - Parameters:
    ///   - event: the event
    func process(event: TouchStreamStateMachineEvent) {
        switch (currentState, event) {
        case (.empty, .began(let location)):
            processEmptyBegan(location)
            currentState = .dragNew
        case (.dragNew, .moved(let location)):
            currentState = processDragNewMoved(location)
        case (.dragNew, .ended(let location)):
            currentState = processDragNewEnded(location)
        case (.dragNew, .cancelled):
            processDragCancelled()
            currentState = .empty
        case (.longTap, .moved):
            currentState = .longTap
        case (.longTap, .ended):
            currentState = processLongTapEnded()
        case (.waypoint, .began(let location)):
            processWaypointBegan(location)
            currentState = .dragWaypoint
        case (.dragWaypoint, .moved(let location)):
            processDragWPMoved(location)
        case (.dragWaypoint, .ended(let location)):
            processDragWPEnded(location)
            currentState = .waypoint
        case (.dragWaypoint, .cancelled):
            processDragCancelled()
            currentState = .waypoint
        case (.poi, .began):
            currentState = .dragPoi
        case (.dragPoi, .moved(let location)):
            processDragPoiMoved(location)
        case (.dragPoi, .ended(let location)):
            processDragPoiEnded(location)
            currentState = .poi
        case (.dragPoi, .cancelled):
            processDragCancelled()
            currentState = .poi
        case (.waypoint, .updated(let element)):
            currentState = processUpdated(element)
        case (.poi, .updated(let element)):
            currentState = processUpdated(element)
        case (.empty, .updated(let element)):
            currentState = processUpdated(element)
        case (_, .updated):
            // ignore updated when in any drag state
            return
        case (_, .runningStateUpdated(let state)):
            currentState = processRunningStateUpdated(state)
        default:
            ULog.e(.tag, "unhandled event \(event) for state \(currentState) ")
        }
    }

    // MARK: - Private Funcs

    /// Processes the began event on the waypoint state.
    ///
    /// - Parameter location: the location of the event
    private func processWaypointBegan(_ location: CGPoint) {
        let location = view.clampedLocation(location: location, objectSize: Constants.outsideCircle)
        dragDirection = .undefined
        originalDragPoint = location
        view.createArrows(dragDirection: dragDirection)
        view.updateArrows(location: location, dragDirection: dragDirection)
    }

    /// Processes the began event on the empty state
    private func processEmptyBegan(_ location: CGPoint) {
        originalDragPoint = location
        startTime = Date(timeIntervalSinceNow: 0)
    }

    /// Processes the moved event on the drag waypoint state.
    ///
    /// - Parameter location: the location of the event
    private func processDragWPMoved(_ location: CGPoint) {
        var location = view.clampedLocation(location: location, objectSize: Constants.outsideCircle)
        if let originalDragPoint = originalDragPoint {
            if dragDirection == .undefined {
                // Define the drag direction.
                let deltaX = abs(originalDragPoint.x - location.x)
                let deltaY = abs(originalDragPoint.y - location.y)
                if deltaX > deltaY && deltaX > Constants.dragMinimumOffset {
                    dragDirection = .horizontal
                } else if deltaY > deltaX && deltaY > Constants.dragMinimumOffset {
                    dragDirection = .vertical
                }
                view.createArrows(dragDirection: dragDirection)
            }
            // Constrain the location to the chosen drag axis.
            switch dragDirection {
            case .undefined:
                break
            case .horizontal:
                location.y = originalDragPoint.y
            case .vertical:
                location.x = originalDragPoint.x
            }
            view.createAxisIfNeeded(location: location, dragDirection: dragDirection)
            view.updateArrows(location: location, dragDirection: dragDirection)
            view.updateGraphic(type: .waypoint, size: Constants.outsideCircle, location: location)
        }
    }

    /// Processes the ended event on the drag waypoint state.
    ///
    /// - Parameter location: the location of the event
    private func processDragWPEnded(_ location: CGPoint) {
        view.clearArrows()
        view.clearAxis()
        let location = view.clampedLocation(location: location, objectSize: Constants.outsideCircle)
        view.updateGraphic(type: .waypoint, size: Constants.outsideCircle, location: location)
        _ = view.saveWaypointLocation(location, dragDirection: dragDirection)
        dragDirection = .undefined
    }

    /// Processes the moved event on the dragpoi state.
    ///
    /// - Parameter location: the location of the event
    private func processDragPoiMoved(_ location: CGPoint) {
        let location = view.clampedLocation(location: location, objectSize: Constants.diamondSize)
        view.updateGraphic(type: .poi, size: Constants.diamondSize, location: location)
    }

    /// Processes the ended event on the drag poi state.
    ///
    /// - Parameter location: the location of the event
    private func processDragPoiEnded(_ location: CGPoint) {
        view.clearArrows()
        view.clearAxis()
        let location = view.clampedLocation(location: location, objectSize: Constants.diamondSize)
        view.updateGraphic(type: .poi, size: Constants.diamondSize, location: location)
        _ = view.savePoiLocation(location)
    }

    /// Processes the moved event on the drag new state.
    ///
    /// - Parameter location: the location of the event
    /// - Returns: the new state
    private func processDragNewMoved(_ location: CGPoint) -> TouchStreamStateMachineState {
        guard let startTime = startTime else {
            return currentState
        }
        let now = Date(timeIntervalSinceNow: 0)
        if now.timeIntervalSince(startTime) > Constants.longTapDelay {
            // display a poi (will be created at the end of the tap)
            let location = view.clampedLocation(location: originalDragPoint ?? location, objectSize: Constants.diamondSize)
            view.createPoi(altitude: 0)
            view.updateGraphic(type: .poi, size: Constants.diamondSize, location: location)
            newPoiLocation = location
            return .longTap
        } else {
            return currentState
        }
    }

    /// Processes the ended event on the long tap state.
    ///
    /// - Returns: the new state
    private func processLongTapEnded() -> TouchStreamStateMachineState {
        if let location = newPoiLocation,
           view.savePoiLocation(location) {
            newPoiLocation = nil
            return .poi
        } else {
            view.clearPoi()
            return .empty
        }
    }

    /// Processes the ended event on the drag new state.
    ///
    /// - Parameter location: the location of the event
    /// - Returns: the new state
    private func processDragNewEnded(_ location: CGPoint) -> TouchStreamStateMachineState {

        let location = view.clampedLocation(location: location, objectSize: Constants.outsideCircle)
        let now = Date(timeIntervalSinceNow: 0)
        if let startTime = startTime, now.timeIntervalSince(startTime) > Constants.longTapDelay {
            if  view.savePoiLocation(location) {
                return .poi
            } else {
                return .empty
            }
        } else if view.saveWaypointLocation(location, dragDirection: .undefined) {
            return .waypoint
        } else {
            return .empty
        }
    }

    /// Processes the cancelled event on all drag states.
    private func processDragCancelled() {
        view.clearArrows()
        view.clearAxis()
    }

    /// Processes the updated event.
    ///
    /// - Parameter element: the stream element
    /// - Returns: the new state
    private func processUpdated(_ element: StreamElement) -> TouchStreamStateMachineState {
        switch element {
        case .none:
            view.clear()
            return .empty
        case .waypoint(.zero, _, _):
            view.clearWayPoint()
            return .empty
        case .waypoint(let location, let altitude, let distance):
            if distance > Constants.minimumVisibleDistance {
                var location = view.pointInStreamView(point: location)
                location = view.clampedLocation(location: location, objectSize: Constants.outsideCircle)
                view.createWaypoint(altitude: altitude)
                view.updateGraphic(type: .waypoint, size: Constants.outsideCircle, location: location)
            } else {
                // Don't display waypoint when too close to drone.
                view.clearWayPoint()
            }
            return .waypoint
        case .poi(.zero, _, _):
            view.clearPoi()
            return .empty
        case .poi(let location, let altitude, let distance):
            if distance > Constants.minimumVisibleDistance {
                view.createPoi(altitude: altitude)
                var location = view.pointInStreamView(point: location)
                location = view.clampedLocation(location: location, objectSize: Constants.diamondSize)
                view.updateGraphic(type: .poi, size: Constants.diamondSize, location: location)
            } else {
                // Don't display POI when too close to drone.
                view.clearPoi()
            }
            return .poi
        case .user(let location):
            view.updateUser(location: location)
        }
        return currentState
    }

    private func processRunningStateUpdated(_ state: TouchAndFlyRunningState) -> TouchStreamStateMachineState {
        switch state {
        case .blocked, .noTarget:
            view.clear()
            return .empty
        default:
            return currentState
        }
    }
}
