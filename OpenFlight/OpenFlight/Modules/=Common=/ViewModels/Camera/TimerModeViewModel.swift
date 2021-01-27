//
//  Copyright (C) 2020 Parrot Drones SAS.
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
import SwiftyUserDefaults

/// State for `TimerModeViewModel`.

final class TimerModeState: ViewModelState, EquatableState, Copying {
    // MARK: - Internal Properties
    /// Boolean describing current timer state.
    fileprivate(set) var inProgress: Bool = false
    /// Countdown before photo capture.
    fileprivate(set) var countDown: Int? = TimerMode.current.value

    // MARK: - Init
    required init() { }

    /// Init.
    ///
    /// - Parameters:
    ///    - inProgress: boolean describing current timer state
    ///    - countDown: countdown before photo capture
    init(inProgress: Bool, countDown: Int?) {
        self.inProgress = inProgress
        self.countDown = countDown
    }

    // MARK: - Internal Funcs
    func isEqual(to other: TimerModeState) -> Bool {
        return self.inProgress == other.inProgress
            && self.countDown == other.countDown
    }

    /// Returns a copy of the object.
    func copy() -> TimerModeState {
        let copy = TimerModeState(inProgress: self.inProgress, countDown: self.countDown)
        return copy
    }
}

/// View model that manages timer mode.

final class TimerModeViewModel: DroneWatcherViewModel<TimerModeState> {
    // MARK: - Private Properties
    private var timerModeObserver: DefaultsDisposable?
    private var countDownTimer: Timer?
    private var camera: Camera2? {
        return drone?.currentCamera
    }

    // MARK: - Private Enums
    private enum Constants {
        static let countDownInterval: TimeInterval = 1.0
    }

    // MARK: - Init
    override init(stateDidUpdate: ((TimerModeState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        listenDefault()
    }

    // MARK: - Deinit
    deinit {
        countDownTimer?.invalidate()
        countDownTimer = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) { }

    // MARK: - Internal Funcs
    /// Starts a countdown for photo.
    func startPhotoTimer() {
        let copy = self.state.value.copy()
        copy.inProgress = true
        self.state.set(copy)
        countDownTimer = Timer.scheduledTimer(withTimeInterval: Constants.countDownInterval, repeats: true) { [weak self] _ in
            if let countDown = self?.state.value.countDown {
                let interval = Int(Constants.countDownInterval)
                if countDown > interval, let copy = self?.state.value.copy() {
                    copy.countDown = countDown - interval
                    self?.state.set(copy)
                } else {
                    self?.camera?.photoCapture?.start()
                    self?.cancelPhotoTimer()
                }
            }
        }
    }

    /// Cancels previously started countdown for photo.
    func cancelPhotoTimer() {
        countDownTimer?.invalidate()
        countDownTimer = nil
        let copy = self.state.value.copy()
        copy.inProgress = false
        copy.countDown = TimerMode.current.value
        self.state.set(copy)
    }
}

// MARK: - Private Funcs
private extension TimerModeViewModel {
    /// Starts watcher for timer setting default.
    func listenDefault() {
        timerModeObserver = Defaults.observe(TimerMode.defaultKey, options: [.new]) { [weak self] _ in
            DispatchQueue.userDefaults.async {
                if self?.state.value.inProgress == false,
                   let copy = self?.state.value.copy() {
                    copy.countDown = TimerMode.current.value
                    self?.state.set(copy)
                }
            }
        }
    }
}
