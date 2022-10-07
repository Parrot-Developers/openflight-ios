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
import OpenFlight
import Combine

class MockFlightPlanRepository: FlightPlanRepository {
    var currentFlightPlan: FlightPlanTestModel?

    public var flightPlansDidChangePublisher: AnyPublisher<Void, Never> {
        return CurrentValueSubject<Void, Never>(())
            .eraseToAnyPublisher()
    }

    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool,
                                withFileUploadNeeded: Bool,
                                completion: ((_ status: Bool) -> Void)?) {
        // do nothing
    }

    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel,
                                byUserUpdate: Bool,
                                toSynchro: Bool,
                                withFileUploadNeeded: Bool) {
        // keep this flight plan for the duration of the test
        currentFlightPlan = FlightPlanTestModel(
            uuid: flightPlanModel.uuid,
            type: flightPlanModel.type,
            dataSetting: flightPlanModel.dataSetting)
    }

    func saveOrUpdateFlightPlan(_ flightPlanModel: FlightPlanModel, byUserUpdate: Bool, toSynchro: Bool) {
        // do nothing
    }

    func saveOrUpdateFlightPlans(_ flightPlanModels: [FlightPlanModel],
                                 byUserUpdate: Bool,
                                 toSynchro: Bool,
                                 withFileUploadNeeded: Bool,
                                 completion: ((Bool) -> Void)?) {
        // do nothing
    }

    func getFlightPlan(withUuid uuid: String) -> FlightPlanModel? {
        // do nothing
        return nil
    }

    func getFlightPlans(withUuids uuids: [String]) -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getFlightPlan(withCloudId cloudId: Int) -> FlightPlanModel? {
        // do nothing
        return nil
    }

    func getFlightPlans(byExcludingTypes excludingTypes: [String]) -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getFlightPlan(withPgyProjectId pgyProjectId: Int64) -> FlightPlanModel? {
        // do nothing
        return nil
    }

    func getFlightPlans(withProjectUuid projectUuid: String,
                        withState: FlightPlanModel.FlightPlanState) -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getFlightPlans(withState: FlightPlanModel.FlightPlanState, byExcludingTypes: [String], completion: @escaping (([FlightPlanModel]) -> Void)) {
        // do nothing
    }

    func getLastFlightDateOfFlightPlan(
        _ flightPlanModel: FlightPlanModel) -> Date? {
        // do nothing
        return nil
    }

    func firstFlightDate(of flightPlanModel: FlightPlanModel) -> Date? {
        // do nothing
        return nil
    }

    func getExecutedFlightPlansCount(withProjectUuid projectUuid: String, excludedUuids: [String]) -> Int {
        // do nothing
        return 0
    }

    func getAllFlightPlansCount() -> Int {
        // do nothing
        return 0
    }

    func getAllFlightPlans() -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getAllFlightPlansToBeDeleted() -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getAllModifiedFlightPlans() -> [FlightPlanModel] {
        // do nothing
        return []
    }

    func getFlightPlansCount(withVersions: [String]) -> Int {
        // do nothing
        return 0
    }

    func getFlightPlans(withVersions: [String], _ completion: @escaping (([FlightPlanModel]) -> Void)) {
        // do nothing
    }

    func deleteOrFlagToDeleteFlightPlans(withUuids uuids: [String], completion: ((_ status: Bool) -> Void)?) {
        // do nothing
    }

    func deleteFlightPlan(withUuid uuid: String, completion: ((Bool) -> Void)?) {
        // do nothing
    }

    func deleteFlightPlans(withUuids uuids: [String]) {
        // do nothing
    }

    func deleteFlightPlans(withUuids uuids: [String], completion: ((Bool) -> Void)?) {
        // do nothing
    }

    func deleteFlightPlans(withExcludedStates excludedStates: [String], completion: ((_ status: Bool) -> Void)?) {
        // do nothing
    }

    func removeCloudIdForAllFlightPlans(completion: ((_ status: Bool) -> Void)?) {
        // do nothing
    }

    func migrateFlightPlansToLoggedUser(_ completion: @escaping () -> Void) {
        // do nothing
    }

    func migrateFlightPlansToAnonymous(_ completion: @escaping () -> Void) {
        // do nothing
    }

}
