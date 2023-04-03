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
import CoreData

fileprivate extension String {
    static let tag = "pictor.engine.repository.session"
}

// MARK: - Protocol
protocol PictorEngineBaseSessionRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineSessionModel {
    /// Get current session synchronously
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    /// - Returns:
    ///     the first session found if any
    func getCurrentSession(in pictorContext: PictorContext) -> PictorEngineSessionModel?

    /// Get current session asynchronously
    ///
    /// - Parameters:
    ///     - pictorContext: pictorContext to work in
    ///     - completion: closure called when finished with the first session found if any
    func getCurrentSession(in pictorContext: PictorContext, completion: @escaping ((Result<PictorEngineSessionModel, PictorEngineError>) -> Void))
}

// MARK: - Implementation
class PictorEngineSessionRepository: PictorEngineRepository<PictorEngineSessionModel>, PictorEngineBaseSessionRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { SessionCD.entityName }

    // MARK: Pictor Engine Base Session Repository Protocol
    func getCurrentSession(in pictorContext: PictorContext) -> PictorEngineSessionModel? {
        var result: PictorEngineSessionModel?

        pictorContext.performAndWait { [unowned self] contextCD in
            if case let .success(currentSession) = self.fetchCurrentSessionCD(contextCD: contextCD) {
                result = currentSession
            }
        }

        return result
    }

    func getCurrentSession(in pictorContext: PictorContext,
                           completion: @escaping ((Result<PictorEngineSessionModel, PictorEngineError>) -> Void)) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.fetchCurrentSessionCD(contextCD: contextCD))
        }
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineSessionModel? {
        guard let record = record as? SessionCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }
        let model = PictorSessionModel(record: record)
        return PictorEngineSessionModel(model: model, record: record)
    }
}

// MARK: - Private
private extension PictorEngineSessionRepository {
    func fetchCurrentSessionCD(contextCD: NSManagedObjectContext) -> Result<PictorEngineSessionModel, PictorEngineError> {
        guard let sessionCD = getCurrentSessionCD(in: contextCD),
              let model = convertToModel(sessionCD, context: contextCD) else {
            return .failure(.unknown)
        }
        return .success(model)
    }
}
