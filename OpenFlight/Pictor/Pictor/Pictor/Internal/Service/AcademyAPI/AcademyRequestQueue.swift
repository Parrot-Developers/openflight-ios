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

internal extension String {
    static let requestQueue = "pictor.academy.request-queue"
}

// MARK: - Protocol
protocol AcademyRequestQueue: AnyObject {
    /// Execute a an API request
    /// - Parameters:
    ///     - request: URLRequest to perform
    ///     - session: current URLSession
    ///     - completion: block contains the server response
    func execute(_ request: URLRequest,
                 _ session: URLSession,
                 _ completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

// MARK: - Implementation
class AcademyRequestQueueImpl: AcademyRequestQueue {
    // MARK: Private
    /// Queue to ensure only one API Request call per session
    private let semaphore: DispatchSemaphore
    /// Store request URLSessionDataTask
    private var dispatchQueue: DispatchQueue

    // MARK: Init
    init() {
        semaphore = DispatchSemaphore(value: 1)
        dispatchQueue = DispatchQueue(label: "pictor-engine-request-queue", qos: .background)
    }

    // MARK: API Request Queue Protocol
    func execute(_ request: URLRequest,
                 _ session: URLSession,
                 _ completion: @escaping (Data?, URLResponse?, Error?) -> Void) {

        dispatchQueue.async { [unowned self] in
            self.semaphore.wait()
            let dataTask = session.dataTask(with: request) { [unowned self] data, response, error in
                self.semaphore.signal()
                DispatchQueue.main.async {
                    completion(data, response, error)
                }
            }
            dataTask.resume()
        }
    }
}
