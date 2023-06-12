//    Copyright (C) 2020 Parrot Drones SAS
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

import GroundSdk
import Combine

private extension ULogTag {
    static let tag = ULogTag(name: "GalleryPanoramaViewModel")
}

// MARK: - Internal Enums
/// Stores possible panorama qualities.
enum PanoramaQuality {
    case good
    case excellent
}

/// A ViewModel for panoramas.
final class GalleryPanoramaGenerationViewModel: NSObject {
    // MARK: - Published Properties
    private(set) var media: GalleryMedia
    /// The step models array.
    @Published private(set) var generationStepModels: [GalleryPanoramaStepModel] = []
    /// The global progress of generation process (including potential download/generation/upload).
    @Published private(set) var generationProgress: Float = 0

    /// The navigation-related delegate.
    weak var delegate: GalleryNavigationDelegate?

    // MARK: - Internal Properties
    /// The status of the current generation step.
    var status: GalleryPanoramaStepStatus {
        guard isCurrentIndexValid else { return .inactive }
        return generationStepModels[currentStepIndex].status
    }

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    /// The media services.
    private let mediaServices: MediaServices
    private var panoramaQuality: PanoramaQuality {
        // Panorama quality may be tweaked in the future according to device model.
        // Use max quality for all devices for now.
        switch AppInfoCore.deviceModel {
        default: return .excellent
        }
    }
    private var photoPano: PhotoPano?
    private var outputUrl: URL?
    private var generationProgressCheckTimer: Timer?
    private var currentStepIndex = 0

    private var isCurrentIndexValid: Bool { currentStepIndex < generationStepModels.count }
    /// Whether download step is active.
    private var isDownloadStepActive: Bool {
        guard currentStepIndex < generationStepModels.count else { return false }
        if case .download = generationStepModels[currentStepIndex].step { return true }
        return false
    }
    /// Whether full generation process is complete.
    private var isFullProcessComplete: Bool {
        generationStepModels
            .filter({ $0.status == .success })
            .count == generationStepModels.count
    }
    /// The media store service.
    private var mediaStoreService: MediaStoreService { mediaServices.mediaStoreService }
    /// The media list service.
    private var mediaListService: MediaListService { mediaServices.mediaListService }

    // MARK: - Init
    ///
    /// - Parameters:
    ///    - mediaServices: the media services
    ///    - media: the panorama media
    init(mediaServices: MediaServices,
         media: GalleryMedia) {
        self.mediaServices = mediaServices
        self.media = media

        super.init()

        listenToMediaStoreService(mediaStoreService)
        setupSteps()

        // debug logs
        $generationStepModels.sink { steps in
            ULog.i(.tag, "Generation steps: \(steps)")
        }
        .store(in: &cancellables)
    }

    /// Sets up panorama generation steps according to sourceType/mediaType.
    func setupSteps() {
        let panoramaType = media.type.toPanoramaType
        var generationSteps: [(GalleryPanoramaStepContent, GalleryPanoramaStepAction)] = []

        switch media.source {
        case .droneInternal,
             .droneSdCard:
            // 2 steps mandatory needed for drone's memory case: generation + upload.
            // Current version doesnot support upload.
            generationSteps = [
                (.generate(panoramaType), generatePanorama),
                (.upload(media.source), uploadPanorama)
            ]

            if let url = AssetUtils.shared.panoramaResourceUrlForMediaId(media.uid, droneUid: media.droneUid) {
                // Only keep upload step, as panorama has already been generated on device.
                outputUrl = url
                generationSteps.remove(at: 0)
            } else if !media.isDownloaded {
                // Insert donwload step @0 if needed (if media has not been downloaded yet).
                generationSteps.insert((.download, downloadMedia), at: 0)
            }
        case .mobileDevice:
            // Only 1 step needed for device's memory.
            generationSteps = [(.generate(panoramaType), generatePanorama)]
        default:
            break
        }

        generationStepModels = generationSteps
            .map { GalleryPanoramaStepModel(step: $0.0, action: $0.1) }
    }
}

// MARK: - VC Events
extension GalleryPanoramaGenerationViewModel {
    func startProcessAsked() {
        ULog.i(.tag, "Start")
        activateCurrentStep()
    }

    func cancelButtonTapped() {
        ULog.i(.tag, "Cancel")
        cancelAllProcesses()
        dismiss()
    }
}

// MARK: - Listeners
private extension GalleryPanoramaGenerationViewModel {

    /// Listens to media store service in order to update states accordingly.
    ///
    /// - Parameter mediaStoreService: the media store service
    func listenToMediaStoreService(_ mediaStoreService: MediaStoreService) {

        mediaStoreService.downloadTaskStatePublisher
            .sink { [weak self] state in
                let progressLog = "progress = \(String(describing: state.progress))"
                let statusLog = "status = \(String(describing: state.status))"
                ULog.i(.tag, "Panorama download state \(progressLog) | \(statusLog)")

                self?.updateDownloadProgress(progress: state.progress, status: state.status)
            }
            .store(in: &cancellables)

        mediaStoreService.uploadTaskStatePublisher
            .sink { [weak self] state in
                let progressLog = "progress = \(String(describing: state.progress))"
                let statusLog = "status = \(String(describing: state.status))"
                ULog.i(.tag, "Panorama upload state \(progressLog) | \(statusLog)")

                self?.updateUploader(progress: state.progress, status: state.status)
            }
            .store(in: &cancellables)

        mediaListService.mediaListPublisher
            .sink { [weak self] list in
                self?.updateLocalPanoramaUrlIfNeeded(list: list)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Process States Handling
private extension GalleryPanoramaGenerationViewModel {
    func activateCurrentStep() {
        ULog.i(.tag, "Panorama activateCurrentStep isCurrentIndexValid \(currentStepIndex) = \(isCurrentIndexValid)")
        guard isCurrentIndexValid else { return }

        updateCurrentStep(with: .active)
        generationStepModels[currentStepIndex].action()
    }

    func updateCurrentStep(with status: GalleryPanoramaStepStatus, activateNextStep: Bool = false) {
        let statusLog = "status = \(status)"
        let activateStepLog = "activateNextStep = \(activateNextStep)"
        let indexValidLog = "isCurrentIndexValid \(currentStepIndex) = \(isCurrentIndexValid)"
        ULog.i(.tag, "Panorama updateCurrentStep with \(statusLog) | \(activateStepLog) | \(indexValidLog)")
        guard isCurrentIndexValid else { return }

        generationStepModels[currentStepIndex].status = status

        if activateNextStep {
            if isFullProcessComplete {
                ULog.i(.tag, "Panorama full process complete")
                closeView()
            } else {
                currentStepIndex += 1
                activateCurrentStep()
            }
        }
    }

    func updateGlobalProgress(_ stepProgress: Float) {
        guard !generationStepModels.isEmpty else {
            generationProgress = 0
            return
        }

        generationProgress = (stepProgress + Float(currentStepIndex)) / Float(generationStepModels.count)
    }

    func closeView() {
        if media.isSphericalPanorama {
            // Spherical panorama => need to call immersive screen display before dismissing.
            DispatchQueue.main.async {
                self.delegate?.showImmersivePanoramaScreen(url: self.outputUrl)
            }
        }

        dismiss(delay: Style.shortAnimationDuration)
    }

    func cancelAllProcesses() {
        terminatePanoramaGeneration()
        if mediaListService.actionState(of: media) == .downloading {
            mediaStoreService.cancelDownload()
        }
    }

    func dismiss(delay: TimeInterval = Style.shortAnimationDuration) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.delegate?.dismissPanoramaGenerationScreen()
            self.generationStepModels.removeAll()
        }
    }
}

// MARK: - Media Download
private extension GalleryPanoramaGenerationViewModel {
    func updateDownloadProgress(progress: Float?, status: MediaTaskStatus?) {
        guard isDownloadStepActive,
              let progress = progress,
              currentStepIndex < generationStepModels.count,
              let status = status, status == .running || status == .error else {
            return
        }

        switch status {
        case .error:
            ULog.e(.tag, "Panorama download failed")
            updateCurrentStep(with: .failure)
            return
        case .running:
            guard generationStepModels[currentStepIndex].status == .failure else { fallthrough }
            updateCurrentStep(with: .active)
        default:
            break
        }

        updateGlobalProgress(Float(progress))
    }

    func downloadMedia() {
        Task {
            for await status in mediaListService.download(medias: [media]) {
                switch status {
                case .complete:
                    updateCurrentStep(with: .success, activateNextStep: true)
                case .error:
                    updateCurrentStep(with: .failure, activateNextStep: false)
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Panorama Generation
private extension GalleryPanoramaGenerationViewModel {
    /// Generates the panorama.
    func generatePanorama() {
        guard let deviceMedia = mediaListService.deviceMedia(for: media) else {
            ULog.e(.tag, "Failed to start panorama generation: media from device not found")
            updateCurrentStep(with: .failure)
            return
        }

        guard let type = deviceMedia.type.toPanoramaType else {
            ULog.e(.tag, "Failed to start panorama generation: panorama type not found")
            updateCurrentStep(with: .failure)
            return
        }

        guard let mediaUrls = deviceMedia.urls else {
            ULog.e(.tag, "Failed to start panorama generation: media urls not found")
            updateCurrentStep(with: .failure)
            return
        }

        guard let mediaFolderPath = deviceMedia.folderPath else {
            ULog.e(.tag, "Failed to start panorama generation: media folder path not found")
            updateCurrentStep(with: .failure)
            return
        }

        guard let mainMediaUrl = deviceMedia.url?.lastPathComponent else {
            ULog.e(.tag, "Failed to start panorama generation: main media url not found")
            updateCurrentStep(with: .failure)
            return
        }

        let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
        let inputs = mediaUrls.filter({!panoramaRelatedEntries.contains(where: $0.lastPathComponent.contains)})
        let width: Int32 = type.width(forQuality: panoramaQuality)
        let height: Int32 = type.height(forQuality: panoramaQuality)
        outputUrl = URL(string: String(mediaFolderPath + "!" + type.rawValue + "_" + mainMediaUrl))

        photoPano = PhotoPano()
        DispatchQueue.main.async {
            self.startTimer()
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let photoPano = self?.photoPano else { return }

            _ = photoPano.process(preset: type.toPanoramaPreset,
                                  inputs: inputs,
                                  width: width,
                                  height: height,
                                  output: self?.outputUrl,
                                  estimationIn: nil,
                                  estimationOut: nil,
                                  description: nil) { [weak self] status in
                if status == .success {
                    // New panorama resource has been created.
                    // => Need to update local mediaInfo dictionary.
                    let mediaInfo = AssetUtils.MediaItemResourceInfo(mediaId: deviceMedia.uid,
                                                                     isPanorama: true)
                    AssetUtils.shared.addMediaInfoToLocalList(mediaInfo, url: self?.outputUrl)
                }
                DispatchQueue.main.async {
                    self?.panoramaGenerationCompletion(status: status)
                }
            }
        }
    }

    func panoramaGenerationCompletion(status: PhotoPanoProcessingStatus) {
        ULog.i(.tag, "Panorama generation status: \(status)")
        let isSuccess = status == .success

        guard isSuccess
                || status == .failed
                || status == .cancelled else {
            return
        }

        if isSuccess {
            // We may get .success info slightly before progress checking timer triggers.
            // => Ensure to update progress.
            updateGlobalProgress(1)
            if media.source.isDeviceSource {
                mediaListService.updateActiveMediaList()
            }
        }

        terminatePanoramaGeneration()
        if status != .cancelled {
            // Do not show the failure status if the process has been cancelled
            updateCurrentStep(with: isSuccess ? .success : .failure, activateNextStep: isSuccess)
        }
    }

    func terminatePanoramaGeneration() {
        generationProgressCheckTimer?.invalidate()
        photoPano?.abort()
    }
}

// MARK: - Upload
private extension GalleryPanoramaGenerationViewModel {
    func startTimer() {
        generationProgressCheckTimer?.invalidate()
        generationProgressCheckTimer = Timer.scheduledTimer(withTimeInterval: Values.oneSecond, repeats: true, block: { [weak self] _ in
            guard let self = self, let photoPano = self.photoPano else { return }

            self.updateGlobalProgress(Float(photoPano.progress()))
        })
    }

    /// Uploads generated panorama to device.
    func uploadPanorama() {
        guard let outputUrl = outputUrl,
              let mediaItem = media.mainMediaItem else {
            ULog.e(.tag, "Failed to start panorama upload: missing preconditions")
            updateCurrentStep(with: .failure)
            return
        }

        Task {
            for await status in mediaStoreService.upload(urls: [outputUrl], to: mediaItem) where status == .error { }
            // updateLocalPanoramaUrlIfNeeded()
            updateCurrentStep(with: .success, activateNextStep: false)
        }
    }

    /// Updates upload progress according to uploader's state.
    ///
    /// - Parameters:
    ///    - progress: the upload task progress
    ///    - status: the upload task status
    func updateUploader(progress: Float?, status: MediaTaskStatus?) {
        guard let progress = progress, let status = status else { return }

        guard !progress.isNaN else {
            ULog.e(.tag, "Panorama upload: invalid progress value")
            updateCurrentStep(with: .failure)
            return
        }

        switch status {
        case .complete:
            ULog.i(.tag, "Panorama upload completed with success")
            updateCurrentStep(with: .success)
        case .error:
            ULog.e(.tag, "Panorama upload failed")
            updateCurrentStep(with: .failure)
        default:
            updateGlobalProgress(progress)
        }
    }

    /// Updates local panorama URL if a corresponding resource is present in drone's memory.
    /// A panorama generated on the device is stored using a local naming convention. It however needs to be updated if its corresponding resource
    /// has been uploaded on the drone (app needs to be able to inform user that the drone's pano resource is also present on the device or can be downloaded).
    ///
    /// - Parameter list: the current media list
    func updateLocalPanoramaUrlIfNeeded(list: [GalleryMedia]) {
        guard media.source.isDroneSource else { return }
        guard let updatedMedia = list.first(where: { $0.uid == media.uid }),
              let updatedResource = updatedMedia.mediaResources?.first(where: { $0.type == .panorama }),
              let localUrl = outputUrl,
              let dstUrl = updatedResource.galleryURL(droneId: media.droneUid, mediaType: media.type) else {
            return
        }

        MediaUtils.moveFile(srcUrl: localUrl, dstUrl: dstUrl)
        AssetUtils.shared.updateMediaInfoUrlInLocalList(srcUrl: localUrl, dstUrl: dstUrl)
        // Update outputUrl with new URL in order to be able to display immersive pano if needed.
        outputUrl = dstUrl
        updateCurrentStep(with: .success, activateNextStep: true)
    }
}
