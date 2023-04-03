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
import Foundation
import Combine

/// Log level
public enum PictorLogLevel {
    case warning
    case info
    case debug
    case error
}

/// Log message
public struct PictorLogMessage {
    public let level: PictorLogLevel
    public let tag: String
    public let message: String
}

final class PictorLogger {
    static let shared = PictorLogger()

    // MARK: - Published properties
    var logPublisher: AnyPublisher<PictorLogMessage, Never> {
        logSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Private properties
    private var logSubject = PassthroughSubject<PictorLogMessage, Never>()

    /// Sends a warning log.
    ///
    /// - Parameters:
    ///   - tag: the tag name to filter log
    ///   - message: the message to log
    func w(_ tag: String, _ message: String) {
        log(level: .warning, tag: tag, message: message)
    }

    /// Sends an information log.
    ///
    /// - Parameters:
    ///   - tag: the tag name to filter log
    ///   - message: the message to log
    func i(_ tag: String, _ message: String) {
        log(level: .info, tag: tag, message: message)
    }

    /// Sends a debug log.
    ///
    /// - Parameters:
    ///   - tag: the tag name to filter log
    ///   - message: the message to log
    func d(_ tag: String, _ message: String) {
        log(level: .debug, tag: tag, message: message)
    }

    /// Sends an error log.
    ///
    /// - Parameters:
    ///   - tag: the tag name to filter log
    ///   - message: the message to log
    func e(_ tag: String, _ message: String) {
        log(level: .error, tag: tag, message: message)
    }
}

private extension PictorLogger {
    func log(level: PictorLogLevel, tag: String, message: String) {
        logSubject.send(PictorLogMessage(level: level,
                                         tag: tag,
                                         message: message))
    }
}
