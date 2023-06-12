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
import CoreData

// MARK: - Protocol
protocol PictorBaseEngineContext {
    /// Update locally only engine properties of list of models in current context
    /// - Parameters:
    ///     - models: array of models to update
    func updateLocalEngine<T: PictorBaseModel>(_ models: [T])

    /// Performs asynchronous specified task closure in context's thread
    /// - Parameters:
    ///     - task: closure called in context's thread
    func perform(_ task: @escaping ((_ context: NSManagedObjectContext) -> Void))

    /// Performs synchronous specified task closure in context's thread
    /// - Parameters:
    ///     - task: closure called in context's thread
    func performAndWait(_ task: @escaping ((_ context: NSManagedObjectContext) -> Void))
}

// MARK: - Pictor Context Extension
extension PictorContext: PictorBaseEngineContext {
    func updateLocalEngine<T: PictorBaseModel>(_ models: [T]) {
        updateEngineProjects(models, local: true)
        updateEngineFlights(models, local: true)
        updateEngineFlightPlans(models, local: true)
        updateEngineGutmaLinks(models, local: true)
    }

    func perform(_ task: @escaping ((_ context: NSManagedObjectContext) -> Void)) {
        currentChildContext.perform { [weak self] in
            guard let self = self else { return }
            task(self.currentChildContext)
        }
    }

    func performAndWait(_ task: @escaping ((_ context: NSManagedObjectContext) -> Void)) {
        currentChildContext.performAndWait {
            task(self.currentChildContext)
        }
    }
}
