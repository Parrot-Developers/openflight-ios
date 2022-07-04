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
import ArsdkEngine
import CoreLocation

protocol TouchStreamViewDelegate: AnyObject {
    /// Update the location of the poi or waypoint
    ///
    /// - Parameters:
    ///    - location: the new location
    ///    - type: the type
    func update(location: CLLocationCoordinate2D, type: TouchStreamView.TypeView)

    /// Update the point of the poi or waypoint in stream
    ///
    /// - Parameters:
    ///    - point: the new point
    ///    - type: the type
    func update(point: CGPoint, type: TouchStreamView.TypeView)
}

/// Touch stream view used to display waypoint / poi / user graphics in stream.
public class TouchStreamView: UIView {

    private enum Constants {
        static let outsideCircle = 42.0
        static let diamandSize = 54.0
        static let userSize = 15.0
    }

    public enum TypeView {
        case waypoint
        case poi
    }

    private var poi: PoiGraphic?
    private var waypoint: WayPointGraphic?
    private var user = UserGraphic()

    private var isMoving = false
    weak var delegate: TouchStreamViewDelegate?

    override public  func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false

        if let touch = touches.first, poi != nil || waypoint != nil {
            let position = touch.location(in: self)
            updateCoordinate(view: poi ?? waypoint, size: Constants.diamandSize, position: position)
            let type: TypeView = poi != nil ? .poi : .waypoint
            delegate?.update(point: getStreamPoint(point: position), type: type)
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = true
        if let touch = touches.first, poi != nil || waypoint != nil {
            updateCoordinate(view: poi ?? waypoint, size: Constants.diamandSize, position: touch.location(in: self))
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        if let touch = touches.first, poi != nil || waypoint != nil {
            let position = touch.location(in: self)
            updateCoordinate(view: poi ?? waypoint, size: Constants.diamandSize, position: position)
            let type: TypeView = poi != nil ? .poi : .waypoint
            delegate?.update(point: getStreamPoint(point: position), type: type)
        }
    }

    // MARK: - Funcs
    /// Set user interaction
    ///
    /// - Parameters:
    ///    - enabled: interaction enabled or not
    public func userInteraction(_ enabled: Bool) {
        self.isUserInteractionEnabled = enabled
        self.isHidden = !enabled
    }

    /// Create if necessary and add waypoint graphic to view
    private func createWaypoint() {
        clearPoi()
        if waypoint == nil {
            waypoint = WayPointGraphic()
            addSubview(waypoint)
            guard let waypoint = waypoint else { return }
            sendSubviewToBack(waypoint)
        }
    }

    /// Create and add user graphic to view
    private func createUser() {
        if !user.isDescendant(of: self) {
            addSubview(user)
        }
    }

    /// Create if necessary and add poi graphic to view
    private func createPoi() {
        clearWayPoint()
        if poi == nil {
            poi = PoiGraphic()
            addSubview(poi)

            guard let poi = poi else { return }
            sendSubviewToBack(poi)
        }
    }

    /// Update Coordinate
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
        guard !isMoving else { return }

        switch streamElement {
        case .none:
            clear()
        case .waypoint(let point, let altitude):
            updateWaypoint(point: point, altitude: altitude)
        case .poi(let point, let altitude):
            updatePoi(point: point, altitude: altitude)
        case .user(let point):
            updateUser(point: point)
        }
    }

    /// Update waypoint position.
    ///
    /// - Parameters:
    ///    - point: the point
    ///    - altitude: the altitude
    private func updateWaypoint(point: CGPoint, altitude: Double) {
        guard !point.isOriginPoint else {
            clearWayPoint()
            return
        }
        createWaypoint()
        updateCoordinate(view: waypoint, size: Constants.outsideCircle, position: getRealPoint(point: point))
        waypoint?.setText("\(Int(altitude))m")
    }

    /// Update poi position.
    ///
    /// - Parameters:
    ///    - point: the point
    ///    - altitude: the altitude
    private func updatePoi(point: CGPoint, altitude: Double) {
        guard !point.isOriginPoint else {
            clearPoi()
            return
        }
        createPoi()
        updateCoordinate(view: poi, size: Constants.diamandSize, position: getRealPoint(point: point))
        poi?.setText("\(Int(altitude))m")
    }

    /// Update user position.
    ///
    /// - Parameters:
    ///    - point: the point
    private func updateUser(point: CGPoint) {
        guard !point.isOriginPoint else {
            user.removeFromSuperview()
            return
        }
        createUser()
        updateCoordinate(view: user, size: Constants.userSize, position: getRealPoint(point: point))
    }

    /// Clear all.
    private func clear() {
        clearWayPoint()
        clearPoi()
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

    /// Adapt point to size of stream
    ///
    /// - Parameters:
    ///    - point: the point to convert
    /// - Returns: the converted point
    private func getRealPoint(point: CGPoint) -> CGPoint {
        return CGPoint(x: frame.width * point.x, y: frame.height * point.y)
    }

    /// Adapt stream point to point
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

    /// Update touch stream view frame
    public func update(frame: CGRect) {
        self.frame = frame
    }
}
