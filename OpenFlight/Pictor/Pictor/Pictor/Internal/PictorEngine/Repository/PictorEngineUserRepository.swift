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
    static let tag = "pictor.engine.repository.user"
}

// MARK: - Protocol
protocol PictorEngineBaseUserRepository: PictorEngineBaseRepository where PictorEngineModelType == PictorEngineUserModel {
    /// Get the current user defined by the only session with the user'UUID
    ///
    ///- Parameters:
    ///    - pictorContext: PIctorContext to fetch
    /// - Returns: `PictorEngineUserModel`
    func getCurrentUser(in pictorContext: PictorContext) -> PictorEngineUserModel?

    /// Check if specifed UUID is new from previous user
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    /// - Returns: list of `PictorEngineProjectModel`
    func isNewUserFromPrevious(in pictorContext: PictorContext, withUuid: String) async -> Bool

    /// Check if specifed UUID is new from previous user
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - completion: callback closure called when finished
    func isNewUserFromPrevious(in pictorContext: PictorContext, withUuid: String, completion: @escaping (Result<Bool, PictorEngineError>) -> Void)

    /// Delete all data for user with specified UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - uuid: user's UUID
    /// - Returns: boolean if successful
    func deleteAllData(in pictorContext: PictorContext, withUuid: String) async -> Bool

    /// Delete all data for user with specified UUID
    ///
    /// - Parameters:
    ///    - pictorContext: PIctorContext to fetch
    ///    - uuid: user's UUID
    ///    - completion: callback closure called when finished
    func deleteAllData(in pictorContext: PictorContext, withUuid: String, completion: @escaping (Result<Bool, PictorEngineError>) -> Void)
}

// MARK: - Implementation
class PictorEngineUserRepository: PictorEngineRepository<PictorEngineUserModel>, PictorEngineBaseUserRepository  {
    // MARK: Override PictorEngineBaseRepository
    override var entityName: String { UserCD.entityName }

    // MARK: Engine User Repository Protocol
    func getCurrentUser(in pictorContext: PictorContext) -> PictorEngineUserModel? {
        var result: PictorEngineUserModel?

        pictorContext.performAndWait { [unowned self] contextCD in
            guard let currentSession = getCurrentSessionCD(in: contextCD) else {
                return
            }

            let userFetchRequest = UserCD.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "uuid == %@", currentSession.userUuid)
            if let userCD = try? contextCD.fetch(userFetchRequest).first {
                result = convertToModel(userCD, context: contextCD)
            }
        }

        return result
    }

    override func convertToModel(_ record: PictorEngineManagedObject, context: NSManagedObjectContext) -> PictorEngineUserModel? {
        guard let record = record as? UserCD else {
            PictorLogger.shared.e(.tag, "❌💾🗂 Bad managed object of \(entityName)")
            return nil
        }
        let model = PictorUserModel(record: record)
        return PictorEngineUserModel(model: model, record: record)
    }

    func isNewUserFromPrevious(in pictorContext: PictorContext, withUuid: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            isNewUserFromPrevious(in: pictorContext, withUuid: withUuid) {
                if case .success(let isNewUser) = $0 {
                    continuation.resume(returning: isNewUser)
                } else {
                    continuation.resume(returning: true)
                }
            }
        }
    }

    func isNewUserFromPrevious(in pictorContext: PictorContext, withUuid: String, completion: @escaping (Result<Bool, PictorEngineError>) -> Void) {
        pictorContext.perform { [unowned self] contextCD in
            completion(self.isNewUserFromPrevious(contextCD: contextCD, withUuid: withUuid))
        }
    }

    func deleteAllData(in pictorContext: PictorContext, withUuid: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            deleteAllData(in: pictorContext, withUuid: withUuid) {
                if case .success(let success) = $0 {
                    continuation.resume(returning: success)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func deleteAllData(in pictorContext: PictorContext,
                       withUuid: String,
                       completion: @escaping (Result<Bool, PictorEngineError>) -> Void) {
        coreDataService.deleteAllUsersData(in: pictorContext.currentChildContext, uuid: withUuid, completion: completion)
    }
}

private extension PictorEngineUserRepository {
    private func isNewUserFromPrevious(contextCD: NSManagedObjectContext, withUuid: String) -> Result<Bool, PictorEngineError> {
        do {
            let fetchRequest: NSFetchRequest<PictorEngineManagedObject> = NSFetchRequest(entityName: self.entityName)
            var subPredicateList = [NSPredicate]()

            let apcIdPredicate = NSPredicate(format: "uuid != %@", withUuid)
            subPredicateList.append(apcIdPredicate)
            let anonymousPredicate = NSPredicate(format: "uuid != %@", PictorUserModel.Constants.anonymousId)
            subPredicateList.append(anonymousPredicate)

            let compoundPredicates = NSCompoundPredicate(type: .and, subpredicates: subPredicateList)
            fetchRequest.predicate = compoundPredicates

            let usersCount = try contextCD.count(for: fetchRequest)
            return .success(usersCount > 0)
        } catch let error {
            return .failure(.fetchError(error))
        }
    }
}
