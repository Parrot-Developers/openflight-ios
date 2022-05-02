//    Copyright (C) 2021 Parrot Drones SAS
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
import Combine

// MARK: - Repository Protocol
public protocol DroneDataRepository: AnyObject {
    // MARK: __ Publisher
    /// Publisher notify changes
    var dronesDidChangePublisher: AnyPublisher<Void, Never> { get }

    // MARK: __ Save Or Update
    /// Save or update DroneData into CoreData from DroneModel
    /// - Parameters:
    ///    - droneModel: DroneModel to save or update
    func saveOrUpdateDrone(fromDroneModel droneModel: DroneModel)

    /// Save or update DroneData into CoreData from DroneMode listl
    /// - Parameters:
    ///    - droneModels: DroneModel list to save or update
    func saveOrUpdateDrones(fromDroneModels droneModels: [DroneModel])

    /// Save or update DroneData into CoreData from DroneMode listl
    /// - Parameters:
    ///    - droneModels: DroneModel list to save or update
    ///    - completion: The callback returning the status.
    func saveOrUpdateDrones(_ droneModels: [DroneModel], completion: ((_ status: Bool) -> Void)?)

    // MARK: __ Get
    /// Get DroneModel with serial
    /// - Parameters:
    ///     - serial: DroneData's serial to search
    /// - Returns:
    ///     - DroneModel object if not found
    func getDrone(withSerial serial: String) -> DroneModel?

    /// Get count of all Drones
    /// - Returns: Count of all Drones
    func getAllDronesCount() -> Int

    /// Get all DroneDataModels from all DroneDatas in CoreData
    /// - Returns:
    ///     -  List of DroneDataModels
    func getAllDrones() -> [DroneModel]

    // MARK: __ Delete
    /// Delete DroneData in CoreData with a specified list of serials
    /// - Parameters:
    ///    - serials: List of serials to search
    func deleteDrones(withSerials serials: [String])
}

// MARK: - Implementation
extension CoreDataServiceImpl: DroneDataRepository {
    // MARK: __ Publisher
    public var dronesDidChangePublisher: AnyPublisher<Void, Never> {
        return dronesDidChangeSubject.eraseToAnyPublisher()
    }

    // MARK: __ Save Or Update
    public func saveOrUpdateDrone(fromDroneModel droneModel: DroneModel) {
        performAndSave({ [unowned self] _ in
            var dronesDataObj: DronesData?
            if let existingDronesData = getDronesDataCD(withSerial: droneModel.droneSerial) {
                dronesDataObj = existingDronesData
            } else if let newDronesData = insertNewObject(entityName: DronesData.entityName) as? DronesData {
                dronesDataObj = newDronesData
            }

            guard let dronesData = dronesDataObj else {
                return false
            }

            dronesData.update(fromDroneModel: droneModel)

            return true
        }, { [unowned self] result in
            switch result {
            case .success:
                dronesDidChangeSubject.send()
            case .failure(let error):
                ULog.e(.dataModelTag,
                       "Error saveOrUpdateDronesData with serial: \(droneModel.droneSerial) - error: \(error)")
            }
        })
    }

    public func saveOrUpdateDrones(fromDroneModels droneModels: [DroneModel]) {
        droneModels.forEach { droneModel in
            var dronesDataObj: DronesData?
            if let existingDronesData = getDronesDataCD(withSerial: droneModel.droneSerial) {
                dronesDataObj = existingDronesData
            } else if let newDronesData = insertNewObject(entityName: DronesData.entityName) as? DronesData {
                dronesDataObj = newDronesData
            }

            if let dronesData = dronesDataObj {
                dronesData.update(fromDroneModel: droneModel)
            }
        }

        saveContext { [unowned self] result in
            switch result {
            case .success:
                dronesDidChangeSubject.send()
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateDrones - error: \(error.localizedDescription)")
            }
        }
    }

    public func saveOrUpdateDrones(_ droneModels: [DroneModel], completion: ((_ status: Bool) -> Void)?) {

        droneModels.forEach { droneModel in
            var dronesDataObj: DronesData?
            if let existingDronesData = getDronesDataCD(withSerial: droneModel.droneSerial) {
                dronesDataObj = existingDronesData
            } else if let newDronesData = insertNewObject(entityName: DronesData.entityName) as? DronesData {
                dronesDataObj = newDronesData
            }

            if let dronesData = dronesDataObj {
                dronesData.update(fromDroneModel: droneModel)
            }
        }

        saveContext { [unowned self] result in
            switch result {
            case .success:
                dronesDidChangeSubject.send()
                completion?(true)
            case .failure(let error):
                ULog.e(.dataModelTag, "Error saveOrUpdateDrones - error: \(error.localizedDescription)")
                completion?(false)
            }
        }
    }

    // MARK: __ Get
    public func getDrone(withSerial serial: String) -> DroneModel? {
        return getDronesDataCD(withSerial: serial)?.model()
    }

    public func getAllDronesCount() -> Int {
        return getAllDronesCountCD(toBeDeleted: false)
    }

    public func getAllDrones() -> [DroneModel] {
        return getAllDronesDatasCD().map({ $0.model() })
    }

    // MARK: __ Delete
    public func deleteDrones(withSerials serials: [String]) {
        guard !serials.isEmpty else {
            return
        }

        performAndSave({ [unowned self] _ in
            let dronesDatas = getDronesDatasCD(withSerials: serials)
            deleteDronesDatasCD(dronesDatas)

            return false
        })
    }
}

// MARK: - Internal
internal extension CoreDataServiceImpl {
    func getAllDronesCountCD(toBeDeleted: Bool?) -> Int {
        let fetchRequest = DronesData.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        fetchRequest.predicate = apcIdPredicate

        return fetchCount(request: fetchRequest)
    }

    func getAllDronesDatasCD() -> [DronesData] {
        let fetchRequest = DronesData.fetchRequest()

        let apcIdPredicate = NSPredicate(format: "apcId == %@", userService.currentUser.apcId)
        fetchRequest.predicate = apcIdPredicate

        return fetch(request: fetchRequest)
    }

    func getDronesDataCD(withSerial serial: String) -> DronesData? {
        let fetchRequest = DronesData.fetchRequest()
        let serialPredicate = NSPredicate(format: "droneSerial == %@", serial)

        fetchRequest.predicate = serialPredicate
        fetchRequest.fetchLimit = 1

        return fetch(request: fetchRequest).first
    }

    func getDronesDatasCD(withSerials serials: [String]) -> [DronesData] {
        guard !serials.isEmpty else {
            return []
        }

        let fetchRequest = DronesData.fetchRequest()
        let serialPredicate = NSPredicate(format: "droneSerial IN %@", serials)
        fetchRequest.predicate = serialPredicate

        let synchroDateSortDesc = NSSortDescriptor(key: "synchroDate", ascending: false)
        fetchRequest.sortDescriptors = [synchroDateSortDesc]

        return fetch(request: fetchRequest)
    }

    func deleteDronesDatasCD(_ dronesDatas: [DronesData]) {
        guard !dronesDatas.isEmpty else {
            return
        }
        delete(dronesDatas) { error in
            ULog.e(.dataModelTag, "Error deleteDronesDatasCD: \(error.localizedDescription)")
        }
    }
}
