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
import Combine
import Pictor

/// Summary about all projects.
public struct ProjectsSummary {
    /// Total number of projects.
    public let numberOfProjects: Int
    /// Total number of FP projects.
    public let numberOfFPProjects: Int
    /// Total number of other projects.
    public let numberOfOtherProjects: Int
    /// The other projects' icon.
    public let otherProjectsIcon: UIImage?

    static let zero = ProjectsSummary(numberOfProjects: 0,
                                      numberOfFPProjects: 0,
                                      numberOfOtherProjects: 0,
                                      otherProjectsIcon: nil)
}

public class DashboardProjectManagerCellModel {

    // MARK: - Public properties
    public var summary: AnyPublisher<ProjectsSummary, Never> { summarySubject.eraseToAnyPublisher() }
    public var isSynchronizingData: AnyPublisher<Bool, Never> { isSynchronizingSubject.eraseToAnyPublisher() }

    // MARK: - Private properties
    private let manager: ProjectManager
    private let synchroService: SynchroService?
    private let projectManagerUiProvider: ProjectManagerUiProvider!
    private var summarySubject = CurrentValueSubject<ProjectsSummary, Never>(ProjectsSummary.zero)
    private var isSynchronizingSubject = CurrentValueSubject<Bool, Never>(false)
    private var cancellables = Set<AnyCancellable>()

    init(manager: ProjectManager,
         synchroService: SynchroService?,
         projectManagerUiProvider: ProjectManagerUiProvider) {
        self.manager = manager
        self.synchroService = synchroService
        self.projectManagerUiProvider = projectManagerUiProvider

        listenProjectsPublisher()
        listenDataSynchronization()

        refreshProjectsSummary(from: manager.allProjectsSummary)
    }

    // MARK: - Private funcs
    private func listenProjectsPublisher() {

        manager.allProjectsSummaryPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.refreshProjectsSummary(from: $0)
        }.store(in: &cancellables)
    }

    private func listenDataSynchronization() {
        synchroService?.statusPublisher
            .sink { [weak self] status in
                self?.isSynchronizingSubject.value = status.isSyncing
            }
            .store(in: &cancellables)
    }

    func refreshProjectsSummary(from allProjectsSummary: AllProjectsSummary) {
        let projectTypes = projectManagerUiProvider.uiParameters().projectTypes
        let otherProjectsIcon = projectTypes.count > 1 ? projectTypes[1].icon : nil

        summarySubject.value = ProjectsSummary(numberOfProjects: allProjectsSummary.numberOfProjects,
                                               numberOfFPProjects: allProjectsSummary.totalFlightPlan,
                                               numberOfOtherProjects: allProjectsSummary.totalPgy,
                                               otherProjectsIcon: otherProjectsIcon)
    }
}
