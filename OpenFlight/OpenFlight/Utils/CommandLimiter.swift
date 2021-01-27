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

/// Utility class that provides the ability to limit commands
/// and avoid having too much calls into CPU costly blocks.

final class CommandLimiter {
    // MARK: - Private Properties
    private var limit: TimeInterval
    private var operationQueue = OperationQueue()
    private var lastCommandTimestamp: TimeInterval = 0.0

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - limit: minimum time between two commands
    public init(limit: TimeInterval) {
        self.limit = limit
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInteractive
    }

    // MARK: - Public Funcs
    /// Add given block to operation queue, if last command
    /// timestamp happened more than `limit` seconds ago.
    ///
    /// - Parameters:
    ///    - block: block to execute
    /// - Returns: true if block will be executed, false otherwise
    @discardableResult
    public func execute(_ block: @escaping () -> Void) -> Bool {
        guard ProcessInfo.processInfo.systemUptime > lastCommandTimestamp + limit else {
            return false
        }
        self.lastCommandTimestamp = ProcessInfo.processInfo.systemUptime
        operationQueue.addOperation(block)
        return true
    }

    /// Cancels all pending operations.
    public func flush() {
        operationQueue.cancelAllOperations()
    }
}
