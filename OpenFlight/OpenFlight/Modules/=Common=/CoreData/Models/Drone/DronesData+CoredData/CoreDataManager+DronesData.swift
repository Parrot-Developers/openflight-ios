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

public protocol DroneDataRepository: AnyObject {
    /// Persist or update user's droneData into CoreData
    /// - Parameters:
    ///     - drone: DroneModel to persist
    func persist(_ drone: DroneModel)

    /// Persist or update user's dronesData into CoreData
    /// - Parameters:
    ///     - drones: List of DroneModel to persist
    func persist(_ drones: [DroneModel])

    /// Load droneData by serial from CoreData
    /// return DroneModel if exist
    /// - Parameters:
    ///     - droneSerial: Drone identifier to load
    func loadDrone(_ droneSerial: String) -> DroneModel?

    /// Load all droneData  from CoreData
    func loadAllDrones() -> [DroneModel]

}

extension CoreDataServiceImpl: DroneDataRepository {
    public func persist(_ drone: DroneModel) {
        // Prepare content to save.
        guard let managedContext = currentContext else { return }

        // Prepare new CoreData entity
        let dronesData: NSManagedObject?

        // Check object if exists.
        if let object = self.loadDronesData("droneSerial", drone.droneSerial) {
            // Use persisted object.
            dronesData = object
        } else {
            // Create new object.
            let fetchRequest: NSFetchRequest<DronesData> = DronesData.fetchRequest()
            guard let name = fetchRequest.entityName else {
                return
            }
            dronesData = NSEntityDescription.insertNewObject(forEntityName: name, into: managedContext)
        }

        guard let dronesDataObject = dronesData as? DronesData else { return }

        dronesDataObject.apcId = drone.apcId
        dronesDataObject.droneSerial = drone.droneSerial
        dronesDataObject.droneCommonName = drone.droneCommonName
        dronesDataObject.modelId = drone.modelId
        dronesDataObject.pairedFor4G = drone.pairedFor4G
        dronesDataObject.synchroDate = drone.synchroDate
        dronesDataObject.synchroStatus = drone.synchroStatus ?? 0

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error during persist DroneData into Coredata: \(error.localizedDescription)")
            }
        }
    }

    public func persist(_ drones: [DroneModel]) {
        for drone in drones {
            self.persist(drone)
        }
    }

    public func loadDrone(_ droneSerial: String) -> DroneModel? {
        return self.loadDronesData("droneSerial", droneSerial)?.model()
    }

    public func loadAllDrones() -> [DroneModel] {
        guard let managedContext = currentContext else {
            return []
        }

        let fetchRequest: NSFetchRequest<DronesData> = DronesData.fetchRequest()
        let predicate = NSPredicate(format: "apcId == %@", Services.hub.userInformation.apcId)
        fetchRequest.predicate = predicate

        var droneModelList = [DroneModel]()

        do {
            droneModelList = try managedContext.fetch(fetchRequest).compactMap({$0.model()})
        } catch let error {
            ULog.e(.dataModelTag, "Error loading DroneData into Coredata: \(error.localizedDescription)")
        }

        return droneModelList
    }

    public func removeDrone(droneSerial: String) {
        guard let dronesData = self.loadDronesData("droneSerial", droneSerial) else {
            return
        }
        self.removeDrone(dronesData)
    }

    public func removeDrone(commonName: String) {
        guard let dronesData = self.loadDronesData("commonName", commonName) else {
            return
        }
        self.removeDrone(dronesData)
    }

}

// MARK: - Utils
private extension CoreDataServiceImpl {
    func loadDronesData(_ key: String?, _ value: String?) -> DronesData? {
        guard let managedContext = currentContext,
              let key = key,
              let value = value else {
            return nil
        }

        /// fetch drone by Serial
        let fetchRequest: NSFetchRequest<DronesData> = DronesData.fetchRequest()
        let serialPredicate = NSPredicate(format: "%K == %@", key, value)
        let currentUserPredicate = NSPredicate(format: "apcId == %@", userInformation.apcId)
        let predicate = NSCompoundPredicate(type: .and, subpredicates: [serialPredicate, currentUserPredicate])
        fetchRequest.predicate = predicate

        do {
            return try (managedContext.fetch(fetchRequest)).first
        } catch let error {
            ULog.e(.dataModelTag, "No DroneData found with: \(key) value: \(value) in CoreData : \(error.localizedDescription)")
            return nil
        }
    }

    func removeDrone(_ droneData: DronesData) {
        guard let managedContext = currentContext else {
            return
        }

        managedContext.delete(droneData)

        managedContext.perform {
            do {
                try managedContext.save()
            } catch let error {
                ULog.e(.dataModelTag, "Error removing DroneData with serial : \(droneData.droneSerial ?? "-") from CoreData : \(error.localizedDescription)")
            }
        }
    }
}
