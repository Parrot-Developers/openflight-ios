// Copyright (C) 2021 Parrot Drones SAS
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
import GroundSdk

public protocol ChallengeSecureElementRepository: AnyObject {
    /// Persist or update ChallengesSecureElement into CoreData
    /// - Parameters:
    ///    - challenge: ChallengesSecureElementModel to persist
    func persist(_ challenge: ChallengesSecureElementModel)

    /// Load all ChallengesSecureElement from CoreData
    func loadAllChallengesSecureElements() -> [ChallengesSecureElementModel]

    /// Load ChallengeSecureElement from CoreData by ChallengeValue
    /// - Parameters:
    ///     - challengeValue: ChallengeValue to search
    ///
    /// - Return:  ChallengesSecureElementModel object
    func loadChallenge(_ challengeValue: String) -> ChallengesSecureElementModel?
}

extension CoreDataManager: ChallengeSecureElementRepository {

    public func persist(_ challenge: ChallengesSecureElementModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let challengesSecureElement: NSManagedObject?

        // Check object if exists.
        if let object = self.loadChallengeSecElement(challenge.challengeValue) {
            // Use persisted object.
            challengesSecureElement = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<ChallengesSecureElement> = ChallengesSecureElement.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            challengesSecureElement = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let challengesSecureElementObject = challengesSecureElement as? ChallengesSecureElement else { return }

        challengesSecureElementObject.challengeValue = challenge.challengeValue
        challengesSecureElementObject.operationType = challenge.operationType
        challengesSecureElementObject.creationDate = challenge.creationDate
        challengesSecureElementObject.challengeSigned = challenge.challengeSigned
        challengesSecureElementObject.synchroStatus = challenge.synchroStatus ?? 0
        challengesSecureElementObject.synchroDate = challenge.synchroDate

        do {
            try managedContext.save()
        } catch let error {
            ULog.e(.dataModelTag, "Error during persist ChallengesSecureElement into Coredata: \(error.localizedDescription)")
        }
    }

    public func loadAllChallengesSecureElements() -> [ChallengesSecureElementModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<ChallengesSecureElement> = ChallengesSecureElement.fetchRequest()

        do {
            return try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error fetching ChallengesSecureElement from Coredata: \(error.localizedDescription)")
            return []
        }
    }

    public func loadChallenge(_ challengeValue: String) -> ChallengesSecureElementModel? {
        return self.loadChallengeSecElement(challengeValue)?.model()
    }
}

// MARK: - Utils
private extension CoreDataManager {
    func loadChallengeSecElement(_ challengeValue: String?) -> ChallengesSecureElement? {
        guard let managedContext = currentContext,
              let challengeValue = challengeValue else {
            return nil
        }

        /// fetch ChallengesSecureElement by ChallengeValue
        let fetchRequest: NSFetchRequest<ChallengesSecureElement> = ChallengesSecureElement.fetchRequest()
        let predicate = NSPredicate(format: "challengeValue == %@", challengeValue)
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No ChallengesSecureElement found with challengeValue : \(challengeValue) in CoreData : \(error.localizedDescription)")
            return nil
        }
    }
}
