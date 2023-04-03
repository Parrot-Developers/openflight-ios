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
import GroundSdk
import Pictor

fileprivate extension ULogTag {
    static let tag = ULogTag(name: "thumbnail.generator.service")
}

private class SafeArray<T: Equatable> {
    private var array: [T] = []
    private var semaphore = DispatchSemaphore(value: 1)

    func add(_ items: [T]) {
        semaphore.wait()
        array.removeAll { items.contains($0) }
        array.append(contentsOf: items)
        semaphore.signal()
    }

    func addPrior(_ items: [T]) {
        semaphore.wait()
        array.removeAll { items.contains($0) }
        array.insert(contentsOf: items, at: 0)
        semaphore.signal()
    }

    func remove(_ items: [T]) {
        semaphore.wait()
        array.removeAll { items.contains($0) }
        semaphore.signal()
    }

    func removeAll() {
        semaphore.wait()
        array.removeAll()
        semaphore.signal()
    }

    func next() -> T? {
        var item: T?
        semaphore.wait()
        item = array.first
        semaphore.signal()
        return item
    }
}

// MARK: - Protocol
public protocol ThumbnailGeneratorService {
    /// Generates thumbnail of flight.
    ///
    /// - Parameters:
    ///     - flights: list of flights
    func generate(for flights: [FlightModel])

    /// Generates thumbnail of flight plans.
    ///
    /// - Parameters:
    ///     - flights: list of flight plans
    func generate(for flightPlans: [FlightPlanModel])
}

// MARK: - Implementation
final class ThumbnailGeneratorServiceImpl {
    // MARK: - Private Properties
    private let userService: PictorUserService
    private let flightRepository: PictorFlightRepository
    private let flightPlanRepository: PictorFlightPlanRepository
    private let metricKitService: MetricKitService
    private var flightUuids = SafeArray<String>()
    private var flightPlanUuids = SafeArray<String>()
    private var didFlightChangedSubject = PassthroughSubject<Void, Never>()
    private var didFlightPlanChangedSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var flightTask: Task<Void, Never>?
    private var flightPlanTask: Task<Void, Never>?

    private let metricLogger: MetricKitLogger

    private enum Constants {
        static let noLocationTimeout: UInt64 = 200_000_000 // In ns
    }

    private enum ThumbnailGeneratorServiceError: Int, Error {
        case requestError
        case noFlight
        case noFlightPlan
    }

    // MARK: - Init
    init(userService: PictorUserService,
         flightRepository: PictorFlightRepository,
         flightPlanRepository: PictorFlightPlanRepository,
         metricKitService: MetricKitService) {
        self.flightRepository = flightRepository
        self.flightPlanRepository = flightPlanRepository
        self.userService = userService
        self.metricKitService = metricKitService

        metricLogger = metricKitService.newLog(category: "Thumbnail")

        listenFlightRepository()
        listenFlightPlanRepository()
        listenUser()
        refreshAllThumbnail()
    }
}

extension ThumbnailGeneratorServiceImpl: ThumbnailGeneratorService {
    func generate(for flights: [FlightModel]) {
        let flightUuids = flights
            .filter { $0.isLocationValid }
            .map { $0.uuid }

        guard !flightUuids.isEmpty else { return }
        generateFlights(for: flightUuids)
    }

    func generate(for flightPlans: [FlightPlanModel]) {
        let flightPlanUuids = flightPlans
            .filter { $0.center?.isValid == true }
            .map { $0.uuid }

        guard !flightPlanUuids.isEmpty else { return }
        generateFlightPlans(for: flightPlanUuids)
    }
}

internal extension ThumbnailGeneratorServiceImpl {
    func refreshAllThumbnail() {
        refreshAllFlightThumbnails()
        refreshAllFlightPlanThumbnails()
    }
}

private extension ThumbnailGeneratorServiceImpl {
    var isFlightTaskCancelled: Bool {
        flightTask?.isCancelled != false
    }

    var isFlightPlanTaskCancelled: Bool {
        flightPlanTask?.isCancelled != false
    }

    func cancelFlightTask() {
        flightTask?.cancel()
        flightTask = nil
    }

    func cancelFlightPlanTask() {
        flightPlanTask?.cancel()
        flightPlanTask = nil
    }

    func generateFlights(for flightUuids: [String]) {
        ULog.i(.tag, "🌉🔵 generate thumbnail for flights \(flightUuids)")

        // Cancels task.
        cancelFlightTask()

        // Insert at the top of list and relaunches task.
        self.flightUuids.addPrior(flightUuids)
        didFlightChangedSubject.send()
    }

    func generateFlightPlans(for flightPlanUuids: [String]) {
        ULog.i(.tag, "🌉🔵 generate thumbnail for flight plans \(flightPlanUuids)")

        // Cancels task.
        cancelFlightPlanTask()

        // Insert at the top of list and relaunches task.
        self.flightPlanUuids.addPrior(flightPlanUuids)
        didFlightPlanChangedSubject.send()
    }

    func requestFlightThumbnails() {
        flightTask = Task {
            metricLogger.beginLog("requestFlightThumbnails")
            while !Task.isCancelled,
                  let flightUuid = flightUuids.next() {
                do {
                    guard let flight = flightRepository.get(byUuid: flightUuid) else {
                        // Flight doesn't exists, continue processing
                        throw ThumbnailGeneratorServiceError.noFlight
                    }

                    var thumbnailImage: UIImage?
                    let coordinate = CLLocationCoordinate2D(latitude: flight.startLatitude,
                                                            longitude: flight.startLongitude)
                    ULog.i(.tag, "🌉🔵 requestFlightThumbnails with uuid: \(flight.uuid), center: (\(coordinate.latitude), \(coordinate.longitude))")
                    if coordinate.isValid {
                        thumbnailImage = try await requestThumbnail(center: coordinate)
                        ULog.i(.tag, "🌉🟢 requestFlightThumbnails with uuid \(flight.uuid) OK")
                    } else {
                        ULog.i(.tag, "🌉🟠 requestFlightThumbnails: Unknown location")
                        try await Task.sleep(nanoseconds: Constants.noLocationTimeout)
                    }

                    try Task.checkCancellation()

                    if var flightToSave = flightRepository.get(byUuid: flightUuid) {
                        if let thumbnailImage = thumbnailImage {
                            if flightToSave.thumbnail != nil {
                                flightToSave.thumbnail?.image = thumbnailImage
                            } else {
                                flightToSave.thumbnail = PictorThumbnailModel(image: thumbnailImage)
                            }
                        } else {
                            flightToSave.thumbnail = nil
                        }
                        let pictorContext = PictorContext.new()
                        pictorContext.updateLocal([flightToSave])
                        pictorContext.commit()
                    }

                    try Task.checkCancellation()

                    flightUuids.remove([flightUuid])

                } catch is CancellationError {
                    ULog.e(.tag, "🌉🟠 requestFlightThumbnails: Task cancelled")
                } catch {
                    ULog.e(.tag, "🌉🔴 Error requesting flight thumbnail: \(error.localizedDescription)")
                    flightUuids.remove([flightUuid])
                }
            }

            // We put nil only if the current task has not been cancelled.
            // It is not possible to put nil on another task because
            // no task is started without canceling the previous one.
            if !Task.isCancelled {
                flightTask = nil
            }
            metricLogger.endLog("requestFlightThumbnails")
        }
    }

    func requestFlightPlanThumbnails() {
        flightPlanTask = Task {
            metricLogger.beginLog("requestFlightPlanThumbnails")
            while !Task.isCancelled,
                  let flightPlanUuid = flightPlanUuids.next() {
                do {
                    guard let flightPlan = flightPlanRepository.get(byUuid: flightPlanUuid) else {
                        // Flight plan doesn't exists, continue processing
                        throw ThumbnailGeneratorServiceError.noFlightPlan
                    }

                    let flightPlanModel = flightPlan.flightPlanModel
                    var thumbnailImage: UIImage?
                    ULog.i(.tag, "🌉🔵 requestFlightPlanThumbnails with uuid: \(flightPlan.uuid), "
                           + "center: (\(String(describing: flightPlanModel.center?.latitude)), \(String(describing: flightPlanModel.center?.longitude)))")
                    if let center = flightPlanModel.center, center.isValid {
                        let coordinate = CLLocationCoordinate2D(latitude: center.latitude,
                                                                longitude: center.longitude)
                        thumbnailImage = try await requestThumbnail(center: coordinate,
                                                                    points: flightPlanModel.points)
                        ULog.i(.tag, "🌉🟢 requestFlightPlanThumbnails with uuid: \(flightPlan.uuid) OK")
                    } else {
                        ULog.i(.tag, "🌉🟠 requestFlightPlanThumbnails: Unknown location")
                        try await Task.sleep(nanoseconds: Constants.noLocationTimeout)
                    }

                    try Task.checkCancellation()

                    if var flightPlanToSave = flightPlanRepository.get(byUuid: flightPlanUuid) {
                        if let thumbnailImage = thumbnailImage {
                            if flightPlanToSave.thumbnail != nil {
                                flightPlanToSave.thumbnail?.image = thumbnailImage
                            } else {
                                flightPlanToSave.thumbnail = PictorThumbnailModel(image: thumbnailImage)
                            }
                        } else {
                            flightPlanToSave.thumbnail = nil
                        }
                        let pictorContext = PictorContext.new()
                        pictorContext.updateLocal([flightPlanToSave])
                        pictorContext.commit()
                    }

                    try Task.checkCancellation()

                    flightPlanUuids.remove([flightPlanUuid])

                } catch is CancellationError {
                    ULog.e(.tag, "🌉🟠 requestFlightPlanThumbnails: Task cancelled")
                } catch {
                    ULog.e(.tag, "🌉🔴 Error requesting flight plan thumbnail: \(error.localizedDescription)")
                    flightPlanUuids.remove([flightPlanUuid])
                }
            }

            // We put nil only if the current task has not been cancelled.
            // It is not possible to put nil on another task because
            // no task is started without canceling the previous one.
            if !Task.isCancelled {
                flightPlanTask = nil
            }
            metricLogger.endLog("requestFlightPlanThumbnails")
        }
    }

    func requestThumbnail(center: CLLocationCoordinate2D,
                          points: [CLLocationCoordinate2D] = [],
                          thumbnailSize: CGSize? = nil) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            ThumbnailRequester().requestThumbnail(center: center,
                                                  points: points) { image in
                guard let image = image else {
                    continuation.resume(with: .failure(ThumbnailGeneratorServiceError.requestError))
                    return
                }
                continuation.resume(with: .success(image))
            }
        }
    }

    func listenUser() {
        userService.userEventPublisher
            .sink { [unowned self] in
                switch $0 {
                case .didLogin:
                    refreshAllThumbnail()
                case .didLogout:
                    cancelFlightTask()
                    self.flightUuids.removeAll()
                    cancelFlightPlanTask()
                    self.flightPlanUuids.removeAll()
                default:
                    // Nothing to do
                    break
                }
            }
            .store(in: &cancellables)
    }

    func listenFlightRepository() {
        // Listens flight changed.
        didFlightChangedSubject
            .sink { [unowned self] _ in
                guard isFlightTaskCancelled else { return }
                requestFlightThumbnails()
            }
            .store(in: &cancellables)

        // Listens new flight created.
        flightRepository.didCreatePublisher
            .merge(with: flightRepository.didUpdatePublisher)
            .sink { [unowned self] uuids in
                let flightUuids = flightRepository.get(byUuids: uuids)
                    .filter { $0.thumbnail == nil }
                    .filter { $0.isLocationValid }
                    .map { $0.uuid }

                guard !flightUuids.isEmpty else { return }
                self.flightUuids.add(flightUuids)
                didFlightChangedSubject.send()
            }
            .store(in: &cancellables)
    }

    func listenFlightPlanRepository() {
        // Listens flight plan changed.
        didFlightPlanChangedSubject
            .sink { [unowned self] _ in
                guard isFlightPlanTaskCancelled else { return }
                requestFlightPlanThumbnails()
            }
            .store(in: &cancellables)

        // Listens new flight plan created.
        flightPlanRepository.didCreatePublisher
            .merge(with: flightPlanRepository.didUpdatePublisher)
            .sink { [unowned self] uuids in
                let flightPlanUuids = flightPlanRepository.get(byUuids: uuids)
                    .filter { $0.thumbnail == nil }
                    .filter { $0.flightPlanModel.center?.isValid == true }
                    .map { $0.uuid }

                guard !flightPlanUuids.isEmpty else { return }
                self.flightPlanUuids.add(flightPlanUuids)
                didFlightPlanChangedSubject.send()
            }
            .store(in: &cancellables)
    }

    func refreshAllFlightThumbnails() {
        // Gets all flights and add to list.
        let flightUuids = flightRepository.getAllWithoutThumbnail()
            .filter { $0.isLocationValid }
            .map { $0.uuid }
        if !flightUuids.isEmpty {
            self.flightUuids.add(flightUuids)
            didFlightChangedSubject.send()
        }
    }

    func refreshAllFlightPlanThumbnails() {
        // Gets all flight plans and add to list.
        let flightPlanUuids = flightPlanRepository.getAllWithoutThumbnail()
            .filter { $0.flightPlanModel.center?.isValid == true }
            .map { $0.uuid }
        if !flightPlanUuids.isEmpty {
            self.flightPlanUuids.add(flightPlanUuids)
            didFlightPlanChangedSubject.send()
        }
    }
}
