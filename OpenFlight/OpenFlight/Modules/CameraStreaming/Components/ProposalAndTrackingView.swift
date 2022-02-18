//    Copyright (C) 2020 Parrot Drones SAS
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

import UIKit
import GroundSdk

// MARK: - Protocols
/// Protocol for ProposalAndTrackingView.
protocol ProposalAndTrackingDelegate: ProposalDelegate {
    /// Called when user has drawn a frame.
    ///
    /// - Parameters:
    ///    - frame: frame drawn by the user
    func didDrawSelection(_ frame: CGRect)
}

/// View that handles proposal and tracking info when follow me is enabled.
class ProposalAndTrackingView: UIView {

    // MARK: - Private Properties
    private var proposalViews = [UInt: TargetView]()
    private var trackingView: TargetView?
    private var drawingView: TargetView?
    private var currentCookie: UInt = 0
    private var contentZone: CGRect?
    private var panGesture: UIPanGestureRecognizer?
    private var longPressGesture: UILongPressGestureRecognizer?
    private var tilt: Double = 0.0
    private weak var delegate: ProposalAndTrackingDelegate?

    // MARK: - Constants
    private enum Constants {
        static let longPressDuration: TimeInterval = 0.5
    }

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addGestures()
    }

    /// Constructor with frame and delegate.
    ///
    /// - Parameters:
    ///    - frame: frame
    ///    - delegate: proposal and tracking delegate
    public init(frame: CGRect, delegate: ProposalAndTrackingDelegate? = nil) {
        super.init(frame: frame)
        self.delegate = delegate
        addGestures()
    }

    // MARK: - Deinit
    deinit {
        removeGestures()
        clearTrackingAndProposals(clearDrawView: true)
    }
}

// MARK: - Internal Funcs
extension ProposalAndTrackingView {

    /// Updates frame and content zone.
    ///
    /// - Parameters:
    ///    - frame: new frame
    func updateFrame(_ frame: CGRect) {
        self.frame = frame
        contentZone = frame
    }

    /// Updates the tilt value.
    ///
    /// - Parameters:
    ///    - tilt: new tilt
    func updateTilt(_ tilt: Double) {
        self.tilt = tilt
    }

    /// Updates tracking info from drone.
    ///
    /// - Parameters:
    ///    - trackingInfo: metadata from the drone
    func trackInfoDidChange(_ trackingInfo: TrackingData) {
        let cookie: UInt = UInt(trackingInfo.tracking.cookie)

        if trackingInfo.hasTracking {
            trackingStatusDidChange(trackingInfo.tracking, cookie: cookie)
        } else if trackingInfo.hasProposal {
            proposalStatusDidChange(trackingInfo.proposal)
        } else {
            clearTrackingAndProposals()
        }
        guard let panGesture = panGesture else {
            clearDrawingView()
            return
        }
        switch panGesture.state {
        case .possible:
            clearDrawingView()
        default:
            break
        }
    }

    /// Clears tracking view and proposal views.
    ///
    /// - Parameters:
    ///    - clearDrawView: boolean to remove the drawing view.
    func clearTrackingAndProposals(clearDrawView: Bool = false) {
        clearTrackingView()
        clearProposalsViews()
        if clearDrawView {
            clearDrawingView()
        }
    }
}

// MARK: - Private Funcs
private extension ProposalAndTrackingView {

    /// Adds pan gesture and long press gesture.
    func addGestures() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(pan:)))
        addGestureRecognizer(panGesture)

        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(longPress:)))
        longPressGesture?.minimumPressDuration = Constants.longPressDuration
        addGestureRecognizer(longPressGesture)
    }

    /// Removes pan gesture and long press gesture.
    func removeGestures() {
        removeGestureRecognizer(panGesture)
        panGesture = nil
        removeGestureRecognizer(longPressGesture)
        longPressGesture = nil
    }

    /// Updates UI with new proposal info.
    ///
    /// - Parameters:
    ///    - metadata: proposal metadata from the drone
    func proposalStatusDidChange(_ metadata: ProposalData?) {
        guard trackingView?.state != .drawing,
              let metadata = metadata else {
                  return
              }
        clearTrackingView()
        if metadata.proposals.isEmpty {
            clearProposalsViews()
        } else {
            var arrayUId = [UInt]()
            for proposal in metadata.proposals {
                arrayUId.append(UInt(proposal.uid))
                if let contentZone = contentZone {
                    let originPoint = CGPoint(x: CGFloat(proposal.x) * frame.width,
                                              y: CGFloat(proposal.y) * frame.height)
                    let frameSize =  CGSize(width: CGFloat(proposal.width) * contentZone.width,
                                            height: CGFloat(proposal.height) * contentZone.height)

                    let proposalFrame = CGRect(origin: originPoint, size: frameSize)
                    // if proposal already exists, we update it with the new frame;
                    // if not, we create it
                    if proposalViews[UInt(proposal.uid)] != nil {
                        proposalViews[UInt(proposal.uid)]?.updateView(frame: proposalFrame, tilt: tilt)
                    } else {
                        let view = TargetView(frame: proposalFrame,
                                              targetId: UInt(proposal.uid),
                                              state: .proposal,
                                              delegate: delegate,
                                              tilt: tilt)
                        addSubview(view)
                        proposalViews[UInt(proposal.uid)] = view
                    }
                }
            }

            // remove unused proposal views
            for proposal in proposalViews where arrayUId.firstIndex(of: proposal.key) == nil {
                proposal.value.removeFromSuperview()
                proposalViews.removeValue(forKey: proposal.key)
            }
        }
    }

    /// Updates UI with new tracking info.
    ///
    /// - Parameters:
    ///    - metadata: tracking metadata from the drone
    ///    - cookie: target cookie
    func trackingStatusDidChange(_ metadata: Vmeta_TrackingMetadata?, cookie: UInt) {
        currentCookie = cookie
        guard let metadata = metadata,
              trackingView?.state != .drawing,
              (cookie == metadata.cookie || cookie == 1) else {
                  return
              }
        clearProposalsViews()
        if !metadata.hasTarget {
            clearTrackingView()
        } else {
            let state = targetState(from: metadata.state)
            if let contentZone = contentZone {
                let originPoint = CGPoint(x: CGFloat(metadata.target.x) * contentZone.width,
                                          y: CGFloat(metadata.target.y) * contentZone.height)
                let frameSize = CGSize(width: CGFloat(metadata.target.width) * contentZone.width,
                                       height: CGFloat(metadata.target.height) * contentZone.height)
                let targetFrame = CGRect(origin: originPoint, size: frameSize)
                updateTrackingView(frame: targetFrame, state: state)
            }
        }
    }

    /// Converts a `Vmeta_TrackingState` state in its `TargetState`equivalent.
    ///
    /// - Parameters:
    ///    - trackingStatus: tracking state to convert
    /// - Returns: the `TargetState`equivalent
    func targetState(from trackingStatus: Vmeta_TrackingState) -> TargetState {
        if trackingStatus == .tsSearching {
            return .pending
        } else if trackingStatus == .tsTracking {
            return .locked
        } else {
            return .drawing
        }
    }

    /// Updates tracking view from the target.
    ///
    /// - Parameters:
    ///    - frame: new size to update
    ///    - state: new target state
    func updateTrackingView(frame: CGRect, state: TargetState) {
        if trackingView == nil {
            let view = TargetView(frame: frame, delegate: delegate, tilt: tilt)
            addSubview(view)
            trackingView = view
        } else if state != .pending {
            trackingView?.updateView(frame: frame, tilt: tilt)
        }
        trackingView?.state = state
    }

    /// Updates drawing view from the frame.
    ///
    /// - Parameters:
    ///    - frame: new size to update
    func updateDrawingView(frame: CGRect) {
        if drawingView == nil {
            let view = TargetView(frame: frame)
            addSubview(view)
            drawingView = view
        } else {
            drawingView?.frame = frame
        }
    }

    /// Clears tracking view.
    func clearTrackingView() {
        trackingView?.removeFromSuperview()
        self.trackingView = nil
    }

    /// Clears drawing view.
    func clearDrawingView() {
        drawingView?.removeFromSuperview()
        drawingView = nil
    }

    /// Clears proposal views.
    func clearProposalsViews() {
        for proposal in proposalViews {
            proposalViews[proposal.key]?.removeFromSuperview()
        }
        proposalViews = [:]
    }

    // MARK: - Helpers
    /// Returns the frame between two points.
    ///
    /// - Parameters:
    ///    - firstPoint: first CGPoint
    ///    - secondPoint: second CGPoint
    /// - Returns: the frame between the two points
    func panFrame(firstPoint: CGPoint, secondPoint: CGPoint) -> CGRect {
        let minPointX = min(firstPoint.x, secondPoint.x)
        let minPointY = min(firstPoint.y, secondPoint.y)
        let width = max(1, abs(firstPoint.x - secondPoint.x))
        let height = max(1, abs(firstPoint.y - secondPoint.y))
        let originPoint = CGPoint(x: minPointX, y: minPointY)
        let frameSize = CGSize(width: width, height: height)
        return CGRect(origin: originPoint, size: frameSize)
    }
}

// MARK: - Gestures
private extension ProposalAndTrackingView {

    /// Action called when user slide his finger on the screen.
    @objc func handlePan(pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: self)
        let location = pan.location(in: self)
        let startingPoint = CGPoint(x: location.x - translation.x,
                                    y: location.y - translation.y)
        let drawFrame = panFrame(firstPoint: location,
                                 secondPoint: startingPoint).intersection(bounds)

        if pan.state == .ended {
            self.delegate?.didDrawSelection(drawFrame)
            self.clearDrawingView()
        } else {
            self.updateDrawingView(frame: drawFrame)
        }
    }

    /// Action called when user press his finger on the screen.
    @objc func handleLongPress(longPress: UILongPressGestureRecognizer) {
        // TODO: Add gesture for long press.
    }
}
