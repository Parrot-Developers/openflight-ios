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

import Foundation

// MARK: - Private Enums
private enum Constants {
    static let defaultKey: String = "delayedTaskDefault"
}

/// Components class used to store protocol properties privately.

final class DelayedTaskComponents {
    /// DispatchWorkItem for delayed task.
    fileprivate var workItems = [String: DispatchWorkItem]()
}

/// Protocol providing the ability to start/cancel a task.

protocol DelayedTaskProvider: class {
    // MARK: - Properties
    /// Components needed for the protocol.
    var delayedTaskComponents: DelayedTaskComponents { get }

    // MARK: - Functions
    /// Starts a task after a given delay.
    ///
    /// - Parameters:
    ///    - task: task to perform
    ///    - delay: delay before performing given task
    ///    - key: unique key (for multiple tasks, otherwise a default is provided)
    ///    - cancelPrevious: whether pending task for key should be cancelled (default: true)
    func setupDelayedTask(_ task: @escaping () -> Void, delay: TimeInterval, key: String, cancelPrevious: Bool)
    /// Cancels pending task for given key.
    func cancelDelayedTask(key: String)
    /// Returns true if a task is pending for given key.
    func isTaskPending(key: String) -> Bool
}

/// Default implementation.

extension DelayedTaskProvider {
    func setupDelayedTask(_ task: @escaping () -> Void, delay: TimeInterval, key: String = Constants.defaultKey, cancelPrevious: Bool = true) {
        // Starts a new task for given key only if none is pending.
        if delayedTaskComponents.workItems[key] == nil || cancelPrevious {
            delayedTaskComponents.workItems[key]?.cancel()
            let taskWorkItem = DispatchWorkItem { [weak self] in
                task()
                self?.delayedTaskComponents.workItems.removeValue(forKey: key)
            }
            delayedTaskComponents.workItems[key] = taskWorkItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: taskWorkItem)
        }
    }

    func cancelDelayedTask(key: String = Constants.defaultKey) {
        delayedTaskComponents.workItems[key]?.cancel()
        delayedTaskComponents.workItems.removeValue(forKey: key)
    }

    func isTaskPending(key: String = Constants.defaultKey) -> Bool {
        return delayedTaskComponents.workItems[key] != nil
    }
}
