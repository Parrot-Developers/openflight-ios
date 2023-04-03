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
#if !PICTOR_EXTENDED

import Foundation
import CoreData
import Combine

public class Pictor {
    // MARK: Singleton
    public static var shared = Pictor()

    // MARK: Public
    public struct Repository {
        public var session: PictorSessionRepository
        public var user: PictorUserRepository
        public var drone: PictorDroneRepository
        public var project: PictorProjectRepository
        public var projectPix4d: PictorProjectPix4dRepository
        public var flight: PictorFlightRepository
        public var flightPlan: PictorFlightPlanRepository
        public var gutmaLink: PictorGutmaLinkRepository
        public var thumbnail: PictorThumbnailRepository
    }
    public struct Service {
        public var user: PictorUserService
        public var synchroService: SynchroService

        public struct AcademyApi {
            public var drone: AcademyApiDroneService
        }
        public var academyApi: AcademyApi
        public var databaseMigration: PictorDatabaseMigrationService
    }

    public private(set) var repository: Repository!
    public private(set) var service: Service!

    public var logPublisher: AnyPublisher<PictorLogMessage, Never> {
        logger.logPublisher.eraseToAnyPublisher()
    }

    // MARK: Private
    private var engine = PictorEngine.shared
    private var logger = PictorLogger.shared

    // MARK: Init
    private init() {
        // - Repository
        let sessionRepository = PictorSessionRepository(coreDataService: engine.coreDataService)
        let userRepository = PictorUserRepository(coreDataService: engine.coreDataService)
        let droneRepository = PictorDroneRepository(coreDataService: engine.coreDataService)
        let projectRepository = PictorProjectRepository(coreDataService: engine.coreDataService)
        let projectPix4dRepository = PictorProjectPix4dRepository(coreDataService: engine.coreDataService)
        let flightRepository = PictorFlightRepository(coreDataService: engine.coreDataService)
        let flightPlanRepository = PictorFlightPlanRepository(coreDataService: engine.coreDataService)
        let gutmaLinkRepository = PictorGutmaLinkRepository(coreDataService: engine.coreDataService)
        let thumbnailRepository = PictorThumbnailRepository(coreDataService: engine.coreDataService)
        repository = Repository(session: sessionRepository,
                                user: userRepository,
                                drone: droneRepository,
                                project: projectRepository,
                                projectPix4d: projectPix4dRepository,
                                flight: flightRepository,
                                flightPlan: flightPlanRepository,
                                gutmaLink: gutmaLinkRepository,
                                thumbnail: thumbnailRepository)

        // - User
        let academySession = AcademySessionProviderImpl(xApiKey: ServicesConstants.academySecretKey)
        let networkService = NetworkServiceImpl()
        let userService = PictorUserServiceImpl(engineSessionRepository: engine.repository.session,
                                                engineUserRepository: engine.repository.user,
                                                academySessionProvider: academySession,
                                                networkService: networkService)

        // - Academy API
        let academyRequestQueue = AcademyRequestQueueImpl()
        let academyService = AcademyServiceImpl(requestQueue: academyRequestQueue,
                                                academySession: academySession)
        let academyDroneService = AcademyApiDroneServiceImpl(academyService: academyService)
        let academyApiService = Service.AcademyApi(drone: academyDroneService)

        // - Database migration
        let coreDataOldService = CoreDataOldService()
        let databaseMigrationService = PictorDatabaseMigrationServiceImpl(coreDataService: engine.coreDataService,
                                                                          coreDataOldService: coreDataOldService,
                                                                          userService: userService)

        let baseSynchroService = BaseSynchroService()

        // - Service
        service = Service(user: userService,
                          synchroService: baseSynchroService,
                          academyApi: academyApiService,
                          databaseMigration: databaseMigrationService)
    }
}

public class BaseSynchroService: SynchroService {
    private var statusSubject = CurrentValueSubject<SynchroServiceStatus, Never>(.synced);

    /// The current synchronization status.
    public var status: SynchroServiceStatus { statusSubject.value }

    /// Published the synchronization status.
    public var statusPublisher: AnyPublisher<SynchroServiceStatus, Never> {
        statusSubject
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    /// Boolean to enable the service
    public var isEnabled: Bool = false
}
#endif
