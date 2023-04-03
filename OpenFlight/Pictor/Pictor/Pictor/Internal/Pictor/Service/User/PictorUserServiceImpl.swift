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

final class PictorUserServiceImpl: PictorUserService {

    // MARK: - Internal Properties
    internal var engineSessionRepository: PictorEngineSessionRepository!
    internal var engineUserRepository: PictorEngineUserRepository!
    internal var academySessionProvider: AcademySessionProvider!
    internal var networkService: NetworkService!
    internal private(set) var currentUserSubject: CurrentValueSubject<PictorEngineUserModel, Never>!
    internal var userEventSubject = PassthroughSubject<PictorUserEvent, Never>()

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var userChangedContext = PictorContext.new()

    init(engineSessionRepository: PictorEngineSessionRepository,
         engineUserRepository: PictorEngineUserRepository,
         academySessionProvider: AcademySessionProvider,
         networkService: NetworkService) {
        self.engineSessionRepository = engineSessionRepository
        self.engineUserRepository = engineUserRepository
        self.academySessionProvider = academySessionProvider
        self.networkService = networkService

        setupSession()
        listenUser()
        listenNetwork()
    }

    var currentUser: PictorUserModel {
        currentUserSubject.value.userModel
    }

    var currentUserPublisher: AnyPublisher<PictorUserModel, Never> {
        currentUserSubject
            .map { $0.userModel }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var userEventPublisher: AnyPublisher<PictorUserEvent, Never> {
        userEventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    var nbFreemiumProjectsDefault: Int { 3 }
}

internal extension PictorUserServiceImpl {
    /// Save agreement changed.
    ///
    /// - Parameters:
    ///   - isAgreementChanged: Tells if agreement changed
    ///   - completion: Callback called when the user is saved
    func saveAgreementChanged(isAgreementChanged: Bool) {
        let pictorContext = PictorContext.new()
        var engineUserModel = currentUserSubject.value
        engineUserModel.userModel.isAgreementChanged = isAgreementChanged
        pictorContext.update([engineUserModel])
        pictorContext.commit()
    }

    /// Updates private mode of the current user
    ///
    /// - Parameters:
    ///   - isPrivateMode: `true` if the user is inprivate mode, `false` otherwise
    ///   - completion: Callback called when the user is saved
    func savePrivateMode(isPrivateMode: Bool) {
        let pictorContext = PictorContext.new()
        var engineUserModel = currentUserSubject.value
        engineUserModel.userModel.isPrivateMode = isPrivateMode
        engineUserModel.userModel.isAgreementChanged = !currentUser.isAnonymous
        pictorContext.update([engineUserModel])
        pictorContext.commit()

        currentUserSubject.value = engineUserModel
        userEventSubject.send(.didChangePrivateMode)
    }
}

private extension PictorUserServiceImpl {
    func createAnonymousUser() -> PictorEngineUserModel {
        return PictorEngineUserModel(userModel: PictorUserModel.createAnonymous())
    }

    func createAnonymousSession() {
        let pictorContext = PictorContext.new()
        let anonymousUser = createAnonymousUser()
        pictorContext.create([anonymousUser])

        let sessionModel = PictorSessionModel(uuid: UUID().uuidString,
                                              pix4dEmail: "",
                                              pix4dAccessToken: nil,
                                              pix4dRefreshToken: nil,
                                              pix4dPremiumTokenExpirationDate: nil,
                                              pix4dPremiumAccountScopes: nil,
                                              pix4dPremiumAccountTokenType: nil,
                                              pix4dPremiumProjectsCountLastSyncDate: nil,
                                              pix4dFreemiumProjectsCountLastSyncDate: nil,
                                              permanentRemainingPix4dProjects: nbFreemiumProjectsDefault,
                                              temporaryRemainingPix4dProjects: nbFreemiumProjectsDefault)
        let engineSessionModel = PictorEngineSessionModel(sessionModel: sessionModel,
                                                          userUuid: anonymousUser.uuid)
        pictorContext.create([engineSessionModel])
        pictorContext.commit()
    }

    func setupSession() {
        let pictorContext = PictorContext.new()
        if engineSessionRepository.getCurrentSession(in: pictorContext) == nil {
            // no session, create anonymous session !
            createAnonymousSession()
        }

        if let currentUser = engineUserRepository.getCurrentUser(in: pictorContext) {
            currentUserSubject = CurrentValueSubject(currentUser)
        }
    }

    func listenNetwork() {
        networkService.isNetworkReachablePublisher
            .sink { [unowned self] in
                if $0 {
                    configure()
                }
            }
            .store(in: &cancellables)
    }

    func listenUser() {
        currentUserPublisher
            .compactMap { $0.apcToken }
            .removeDuplicates()
            .sink { [unowned self] apcToken in
                self.academySessionProvider.refreshSession(apcToken)
            }
            .store(in: &cancellables)

        engineUserRepository.didUpdatePublisher
            .sink { [unowned self] uuids in
                engineUserRepository.get(in: userChangedContext,
                                         byUuids: uuids) { [unowned self] result in
                    switch result {
                    case .success(let users):
                        guard let user = users.first(where: { $0.uuid == currentUserSubject.value.uuid }) else {
                            return
                        }
                        currentUserSubject.value = user
                    case .failure:
                        break
                    }
                }
            }
            .store(in: &cancellables)
    }
}
