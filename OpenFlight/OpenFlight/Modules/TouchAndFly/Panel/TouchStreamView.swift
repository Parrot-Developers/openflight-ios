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
import GroundSdk
import ArsdkEngine
import CoreLocation

protocol TouchStreamViewDelegate: AnyObject {
    /// Update the point of the poi or waypoint in stream.
    ///
    /// - Parameters:
    ///    - point: the new point
    /// - Returns: true if the point was updated
    func updatePoi(point: CGPoint) -> Bool

    /// Update the point of the poi or waypoint in stream.
    ///
    /// - Parameters:
    ///    - point: the new or updated waypoint
    ///    - dragDirection: the direction of the update (undefined if new point)
    /// - Returns: true if the point was updated
    func updateWaypoint(point: CGPoint, dragDirection: TouchStreamView.DragDirection) -> Bool
}

/// Touch stream view used to display waypoint / poi / user graphics in stream.
public class TouchStreamView: UIView {

    private enum Constants {
        static let outsideCircle = 42.0
        static let diamandSize = 54.0
        static let userSize = 15.0
        static let dragMinimumOffset = 5.0
        static let altitudeOffsetRatio = 15.0
    }

    public enum TypeView {
        case waypoint
        case poi
    }

    enum DragDirection {
        case undefined
        case horizontal
        case vertical
    }

    private var poi: PoiGraphic?
    private var waypoint: WayPointGraphic?
    private var user = UserGraphic()
    private var arrowHorizontal: ArrowGraphic?
    private var arrowVertical: ArrowGraphic?
    private var axis: AxisGraphic?
    private var cancellables = Set<AnyCancellable>()
    private lazy var stateMachine: TouchStreamStateMachine = {
        TouchStreamStateMachine(view: self)
    }()

    var viewModel: TouchStreamViewModel?
    weak var delegate: TouchStreamViewDelegate?

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touches.count == 1 else { return }
        let location = touch.location(in: self)
        stateMachine.process(event: .began(location))
    }

    override public  func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        stateMachine.process(event: .ended(location))
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if touches.count == 1 {
            stateMachine.process(event: .moved(location))
        } else {
            stateMachine.process(event: .cancelled)
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        stateMachine.process(event: .cancelled)
    }

    func listen() {
        listenRunningState()
        listenHudVisibility()
    }

    func listenRunningState() {
        viewModel?.$runningState.sink { state in
            guard let state = state else { return }
            self.stateMachine.process(event: .runningStateUpdated(state))
        }
        .store(in: &cancellables)
    }

    func listenHudVisibility() {
        viewModel?.$isHudVisible.sink { isVisible in
            if !isVisible {
                self.stateMachine.process(event: .cancelled)
            }
        }
        .store(in: &cancellables)
    }

    /// Set user interaction.
    ///
    /// - Parameters:
    ///    - enabled: interaction enabled or not
    public func setUserInteraction(_ enabled: Bool) {
        self.isUserInteractionEnabled = enabled
    }

    /// Create and add user graphic to view.
    private func createUser() {
        if !user.isDescendant(of: self) {
            addSubview(user)
        }
    }

    /// Updates the frame of a view based on a size and a center position.
    ///
    /// - Parameters:
    ///    - view: the view to update
    ///    - size: the size of the graphic
    ///    - position: the position of the graphic
    private func updateCoordinate(view: UIView?, size: Double, position: CGPoint) {
        guard let view = view else { return }
        view.frame = CGRect(x: position.x - size / 2.0,
                            y: position.y - size / 2.0,
                            width: size,
                            height: size)
    }

    /// Display stream element.
    ///
    /// - Parameters:
    ///    - streamElement: the stream element
    public func displayPoint(streamElement: StreamElement) {
        stateMachine.process(event: .updated(streamElement))
    }

    /// Normalizes the coordinates of a point in the stream view.
    ///
    /// - Parameters:
    ///    - point: the point to convert
    /// - Returns: the converted point
    private func getStreamPoint(point: CGPoint) -> CGPoint {
        let width = frame.width
        let height = frame.height
        guard width != 0 && height != 0 else {
            return CGPoint(x: 0, y: 0)
        }
        return CGPoint(x: point.x / width, y: point.y / height)
    }

    /// Update touch stream view frame.
    public func update(frame: CGRect) {
        self.frame = frame
    }
}

extension TouchStreamView: TouchStreamStateMachineView {
    /// Converts a normalized point into steam view coordinates.
    ///
    /// - Parameters:
    ///    - point: the point to convert
    /// - Returns: the converted point
    func pointInStreamView(point: CGPoint) -> CGPoint {
        return CGPoint(x: frame.width * point.x, y: frame.height * point.y)
    }

    /// Clear all.
    func clear() {
        clearWayPoint()
        clearPoi()
        clearArrows()
        clearAxis()
    }

    /// Clear waypoint.
    func clearWayPoint() {
        waypoint?.removeFromSuperview()
        waypoint = nil
    }

    /// Clear poi.
    func clearPoi() {
        poi?.removeFromSuperview()
        poi = nil
    }

    /// Create and display axis arrows.
    ///
    /// Arrows are displayed during a drag event. If a drag direction is defined, only the corresponding arrow is displayed.
    func createArrows(dragDirection: DragDirection) {
        clearArrows()
        if dragDirection != .horizontal {
            arrowVertical = ArrowGraphic(color: ColorName.greenSpring.color, direction: .vertical)
            addSubview(arrowVertical)
            guard let arrowVertical = arrowVertical else { return }
            sendSubviewToBack(arrowVertical)
        }
        if dragDirection != .vertical {
            arrowHorizontal = ArrowGraphic(color: ColorName.orange.color, direction: .horizontal)
            addSubview(arrowHorizontal)
            guard let arrowHorizontal = arrowHorizontal else { return }
            sendSubviewToBack(arrowHorizontal)
        }
    }

    /// Update arrows.
    ///
    /// - Parameters:
    ///    - location: the location of the origin of the arrow
    func updateArrows(location: CGPoint, dragDirection: DragDirection) {
        if dragDirection != .horizontal {
            arrowVertical?.updatePosition(location)
        }
        if dragDirection != .vertical {
            arrowHorizontal?.updatePosition(location)
        }
    }

    /// Clear arrows.
    func clearArrows() {
        arrowHorizontal?.removeFromSuperview()
        arrowHorizontal = nil
        arrowVertical?.removeFromSuperview()
        arrowVertical = nil
    }

    /// Create if necessary and add waypoint graphic to view.
    ///
    /// - Parameters:
    ///    - altitude: the altitude of the waypoint
    func createWaypoint(altitude: Double) {
        clearPoi()
        if waypoint == nil {
            waypoint = WayPointGraphic()
            addSubview(waypoint)
            guard let waypoint = waypoint else { return }
            sendSubviewToBack(waypoint)
        }
        waypoint?.setText("\(Int(altitude))m")
    }

    /// Create if necessary and add poi graphic to view.
    ///
    /// - Parameters:
    ///    - altitude: the altitude of the POI
    func createPoi(altitude: Double) {
        clearWayPoint()
        if poi == nil {
            poi = PoiGraphic()
            addSubview(poi)

            guard let poi = poi else { return }
            sendSubviewToBack(poi)
        }
        poi?.setText("\(Int(altitude))m")
    }

    /// Update POI or WP graphic.
    ///
    /// - Parameters:
    ///    - type: the type (POI/WP)
    ///    - size: the size of the graphic
    ///    - location: the location of the graphic (center)
    func updateGraphic(type: TypeView, size: Double, location: CGPoint) {
        var graphic: UIView?
        switch type {
        case .poi:
            graphic = poi
        case .waypoint:
            graphic = waypoint
        }
        guard let graphic = graphic else { return }
        graphic.frame = CGRect(x: location.x - size / 2.0,
                            y: location.y - size / 2.0,
                            width: size,
                            height: size)
    }

    /// Update user location.
    ///
    /// - Parameters:
    ///    - location: user location
    func updateUser(location: CGPoint) {
        guard !location.isOriginPoint else {
            user.removeFromSuperview()
            return
        }
        let graphicLocation = pointInStreamView(point: location)
        createUser()
        user.frame = CGRect(x: graphicLocation.x - Constants.userSize / 2.0,
                            y: graphicLocation.y - Constants.userSize / 2.0,
                            width: Constants.userSize,
                            height: Constants.userSize)
    }

    /// Create and display an axis.
    ///
    /// Axis are displayed during a drag event one a direction has been defined.
    func createAxisIfNeeded(location: CGPoint, dragDirection: DragDirection) {
        if axis != nil {
            return
        }
        switch dragDirection {
        case .undefined:
            return
        case .horizontal:
            axis = AxisGraphic(location: location, size: frame.size, direction: .horizontal)
        case .vertical:
            axis = AxisGraphic(location: location, size: frame.size, direction: .vertical)
        }
        addSubview(axis)
        guard let axis = axis else { return }
        sendSubviewToBack(axis)
    }

    /// Clear axis.
    func clearAxis() {
        axis?.removeFromSuperview()
        axis = nil
    }

    /// Clamp the location.
    /// Based on its size, keeps the object in the parent frame
    /// 
    /// - Parameters:
    ///    - location: original touch location
    ///    - objectSize: size of the graphic object
    func clampedLocation(location: CGPoint, objectSize: Double) -> CGPoint {
        guard self.frame.size.width > objectSize, self.frame.size.height > objectSize else {
            return location
        }
        let halfObjectSize = objectSize / 2.0
        var graphicLocation = location
        graphicLocation.x = (halfObjectSize...self.frame.size.width - halfObjectSize).clamp(location.x)
        graphicLocation.y = (halfObjectSize...self.frame.size.height - halfObjectSize).clamp(location.y)
        return graphicLocation
    }

    /// Saves a waypoint at a given location.
    ///
    /// Calls the TouchStreamViewDelegate to save a waypoint.
    ///
    /// - Parameters:
    ///    - location: original touch location
    /// - Returns: true if the point could be saved
    func saveWaypointLocation(_ location: CGPoint, dragDirection: DragDirection) -> Bool {
        return delegate?.updateWaypoint(point: getStreamPoint(point: location), dragDirection: dragDirection) ?? false
    }

    /// Saves a poi.
    ///
    /// Calls the TouchStreamViewDelegate to save a poi.
    ///
    /// - Parameters:
    ///    - location: original touch location
    /// - Returns: true if the poi could be saved
    func savePoiLocation(_ location: CGPoint) -> Bool {
        return delegate?.updatePoi(point: getStreamPoint(point: location)) ?? false
    }

}
