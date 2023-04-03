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

// MARK: - Pictor Engine
class PictorEngine {
    // MARK: Singleton
    static let shared = PictorEngine()

    var coreDataService: CoreDataService!

    // MARK: Repository
    struct Repository {
        var session: PictorEngineSessionRepository
        var user: PictorEngineUserRepository
        var drone: PictorEngineDroneRepository
        var project: PictorEngineProjectRepository
        var projectPix4d: PictorEngineProjectPix4dRepository
        var flight: PictorEngineFlightRepository
        var flightPlan: PictorEngineFlightPlanRepository
        var gutmaLink: PictorEngineGutmaLinkRepository
        var thumbnail: PictorEngineThumbnailRepository
    }
    var repository: Repository!

    private init() {
        coreDataService = CoreDataStackService.shared

        // - Repository
        let sessionRepository = PictorEngineSessionRepository(coreDataService: coreDataService)
        let userRepository = PictorEngineUserRepository(coreDataService: coreDataService)
        let droneRepository = PictorEngineDroneRepository(coreDataService: coreDataService)
        let projectRepository = PictorEngineProjectRepository(coreDataService: coreDataService)
        let projectPix4dRepository = PictorEngineProjectPix4dRepository(coreDataService: coreDataService)
        let flightRepository = PictorEngineFlightRepository(coreDataService: coreDataService)
        let flightPlanRepository = PictorEngineFlightPlanRepository(coreDataService: coreDataService)
        let gutmaLinkRepository = PictorEngineGutmaLinkRepository(coreDataService: coreDataService)
        let thumbnailRepository = PictorEngineThumbnailRepository(coreDataService: coreDataService)
        repository = Repository(session: sessionRepository,
                                user: userRepository,
                                drone: droneRepository,
                                project: projectRepository,
                                projectPix4d: projectPix4dRepository,
                                flight: flightRepository,
                                flightPlan: flightPlanRepository,
                                gutmaLink: gutmaLinkRepository,
                                thumbnail: thumbnailRepository)
    }
}

// MARK: - Error
enum PictorEngineError: Error {
    case unknown
    case fetchError(Error)
}
