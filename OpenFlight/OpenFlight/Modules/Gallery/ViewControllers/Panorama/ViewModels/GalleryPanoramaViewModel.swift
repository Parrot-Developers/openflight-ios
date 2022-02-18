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

// MARK: - Internal Enums
/// Stores possible panorama qualities.
enum PanoramaQuality {
    case good
    case excellent
}

/// A ViewModel for panoramas.
final class GalleryPanoramaViewModel: NSObject {
    // MARK: - Published Properties
    /// The step models array.
    @Published private(set) var generationStepModels: [GalleryPanoramaStepModel] = []
    /// The global progress of generation process (including potential download/generation/upload).
    @Published private(set) var generationProgress: Float = 0

    // MARK: - Internal Properties
    /// The gallery media view model.
    weak var galleryMediaViewModel: GalleryMediaViewModel?
    /// The index of the gallery media.
    var mediaIndex: Int?
    /// The status of the current generation step.
    var status: GalleryPanoramaStepStatus {
        guard isCurrentIndexValid else { return .inactive }
        return generationStepModels[currentStepIndex].status
    }

    // MARK: - Private
    private var cancellables = Set<AnyCancellable>()
    private weak var coordinator: GalleryCoordinator?
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
    private var mediaListener: GalleryMediaListener?
    private var currentStepIndex = 0

    // Convenience Computed Properties
    private var media: GalleryMedia? {
        guard let mediaIndex = mediaIndex else { return nil }
        return galleryMediaViewModel?.getMedia(index: mediaIndex)
    }
    private var mediaFromDevice: GalleryMedia? {
        guard let media = media else { return nil }
        return galleryMediaViewModel?.deviceViewModel?.getMediaFromUid(media.uid)
    }
    private var isCurrentIndexValid: Bool { currentStepIndex < generationStepModels.count }
    private var isDownloadingActiveStep: Bool {
        guard currentStepIndex < generationStepModels.count else { return false }

        switch generationStepModels[currentStepIndex].step {
        case .download: return true
        default: return false
        }
    }
    private var isUploadingActiveStep: Bool {
        guard currentStepIndex < generationStepModels.count else { return false }

        switch generationStepModels[currentStepIndex].step {
        case .upload: return true
        default: return false
        }
    }
    private var isFullProcessComplete: Bool {
        galleryMediaViewModel?.mediaBrowsingViewModel.panoramaGenerationStatus != .success
            && generationStepModels
            .filter({ $0.status == .success })
            .count == generationStepModels.count
    }

    // MARK: - Init
    ///
    /// - Parameters:
    ///    - galleryMediaViewModel: The gallery media view model.
    ///    - coordinator: The gallery coordinator.
    ///    - mediaIndex: The index of the gallery media.
    init(galleryMediaViewModel: GalleryMediaViewModel?,
         coordinator: GalleryCoordinator?,
         mediaIndex: Int? = nil) {
        self.galleryMediaViewModel = galleryMediaViewModel
        self.coordinator = coordinator
        self.mediaIndex = mediaIndex

        super.init()

        setupSteps()
        listenToDownload()
        listenToMedia()
    }

    /// Sets up panorama generation steps according to sourceType/mediaType.
    func setupSteps() {
        guard let galleryMediaViewModel = galleryMediaViewModel,
              let panoramaType = media?.type.toPanoramaType else {
            return
        }

        var generationSteps: [(GalleryPanoramaStepContent, GalleryPanoramaStepAction)] = []

        switch galleryMediaViewModel.sourceType {
        case .droneInternal,
             .droneSdCard:
            // 2 steps mandatory needed for drone's memory case: generation + upload.
            // Current version doesnot support upload.
            generationSteps = [
                (.generate(panoramaType), generatePanorama),
                (.upload(galleryMediaViewModel.sourceType), uploadPanorama)
            ]

            if let url = AssetUtils.shared.panoramaResourceUrlForMediaId(media?.uid) {
                // Only keep upload step, as panorama has already been generated on device.
                outputUrl = url
                generationSteps.remove(at: 0)
            } else if media?.downloadState == .toDownload {
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

    // MARK: - Deinit
    deinit {
        stopListeningToMedia()
    }
}

// MARK: - VC Events
extension GalleryPanoramaViewModel {
    func startProcessAsked() {
        activateCurrentStep()
    }

    func cancelButtonTapped() {
        cancelAllProcesses()
        dismiss()
    }
}

// MARK: - Listeners
private extension GalleryPanoramaViewModel {
    func listenToDownload() {
        // Listen to drone's memory download state changes.
        guard let galleryMediaViewModel = galleryMediaViewModel else { return }
        galleryMediaViewModel.$downloadProgress.compactMap({ $0 })
            .combineLatest(galleryMediaViewModel.$downloadStatus.compactMap({ $0 }))
            .sink { [unowned self] (progress, status) in
                updateDownloadProgress(progress: progress, status: status)
            }
            .store(in: &cancellables)
    }

    func listenToMedia() {
        mediaListener = galleryMediaViewModel?.registerListener { [unowned self] _ in
            if isFullProcessComplete {
                // Notify browsingVM of panorama completion for gallery refresh.
                galleryMediaViewModel?.mediaBrowsingViewModel.didUpdatePanoramaGeneration(.success)
                // Update local panorama URL with uploaded resource UID if needed.
                updateLocalPanoramaUrlIfNeeded()
                // Process complete => exit.
                closeView()
            }
        }
    }

    func stopListeningToMedia() {
        galleryMediaViewModel?.unregisterListener(mediaListener)
    }
}

// MARK: - Process States Handling
private extension GalleryPanoramaViewModel {
    func activateCurrentStep() {
        guard isCurrentIndexValid else { return }

        updateCurrentStep(with: .active)
        generationStepModels[currentStepIndex].action()
    }

    func updateCurrentStep(with status: GalleryPanoramaStepStatus, activateNextStep: Bool = false) {
        guard isCurrentIndexValid else { return }

        generationStepModels[currentStepIndex].status = status

        guard !isFullProcessComplete else {
            // All steps have been completed => Need to refresh gallery.
            galleryMediaViewModel?.refreshMedias(source: media?.source)
            return
        }

        if activateNextStep {
            currentStepIndex += 1
            activateCurrentStep()
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
        guard media?.type.toPanoramaType == .sphere,
              let viewModel = galleryMediaViewModel,
              let url = outputUrl else {
            dismiss()
            return
        }

        // Spherical panorama => need to call immersive screen display before dismissing.
        coordinator?.showPanoramaVisualisationScreen(viewModel: viewModel, url: url)
        dismiss(delay: Style.shortAnimationDuration)
    }

    func cancelAllProcesses() {
        stopListeningToMedia()
        terminatePanoramaGeneration()

        if media?.downloadState == .downloading {
            galleryMediaViewModel?.cancelDownloads()
        }
    }

    func dismiss(delay: TimeInterval = Style.shortAnimationDuration) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.galleryMediaViewModel?.mediaBrowsingViewModel.didUpdatePanoramaGeneration(.inactive)
            self.coordinator?.dismissPanoramaGenerationScreen()
            self.generationStepModels.removeAll()
        }
    }
}

// MARK: - Media Download
private extension GalleryPanoramaViewModel {
    func updateDownloadProgress(progress: Float, status: MediaTaskStatus) {
        guard status == .running || status == .error else {
            return
        }

        if status == .error {
            // Keep current progress when .failure rises.
            // Update status and exit.
            updateCurrentStep(with: .failure)
            return
        }

        updateGlobalProgress(Float(progress))
    }

    func downloadMedia() {
        guard let galleryMediaViewModel = galleryMediaViewModel,
              let currentMedia = media,
              currentMedia.downloadState == .toDownload else {
            return
        }

        galleryMediaViewModel.downloadMedias([currentMedia]) { [weak self] success in
            guard let self = self,
                  self.isDownloadingActiveStep,
                  success else {
                return
            }

            self.updateCurrentStep(with: .success, activateNextStep: true)
        }
    }
}

// MARK: - Panorama Generation
private extension GalleryPanoramaViewModel {
    /// Generates the panorama.
    func generatePanorama() {
        // Refresh gallery medias on device.
        galleryMediaViewModel?.refreshMedias(source: .mobileDevice)
        galleryMediaViewModel?.mediaBrowsingViewModel.didUpdatePanoramaGeneration(.active)

        guard let mediaFromDevice = mediaFromDevice,
              let type = mediaFromDevice.type.toPanoramaType,
              let mediaUrls = mediaFromDevice.urls,
              let mediaFolderPath = mediaFromDevice.folderPath,
              let mainMediaUrl = mediaFromDevice.url?.lastPathComponent else {
            updateCurrentStep(with: .failure)
            return
        }

        let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
        let inputs = mediaUrls.filter({!panoramaRelatedEntries.contains(where: $0.lastPathComponent.contains)})
        let width: Int32 = type.width(forQuality: panoramaQuality)
        let height: Int32 = type.height(forQuality: panoramaQuality)
        outputUrl = URL(string: String(mediaFolderPath + "!" + type.rawValue + "_" + mainMediaUrl))

        photoPano = PhotoPano()
        generationProgressCheckTimer?.invalidate()
        generationProgressCheckTimer = Timer.scheduledTimer(withTimeInterval: Values.oneSecond, repeats: true, block: { [weak self] _ in
            guard let self = self,
                  let photoPano = self.photoPano else {
                return
            }

            self.updateGlobalProgress(Float(photoPano.progress()))
        })

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
                    let mediaInfo = AssetUtils.MediaItemResourceInfo(mediaId: mediaFromDevice.uid,
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
        }

        terminatePanoramaGeneration()
        updateCurrentStep(with: isSuccess ? .success : .failure, activateNextStep: isSuccess)
    }

    func terminatePanoramaGeneration() {
        generationProgressCheckTimer?.invalidate()
        photoPano?.abort()
    }
}

// MARK: - Upload
private extension GalleryPanoramaViewModel {
    /// Uploads generated panorama to device.
    func uploadPanorama() {
        guard let outputUrl = outputUrl,
              let galleryMediaViewModel = galleryMediaViewModel,
              let mediaItem = media?.mainMediaItem else {
            updateCurrentStep(with: .failure)
            return
        }

        galleryMediaViewModel.uploadResources([outputUrl], mediaItem: mediaItem) { [weak self] (status, progress) in
            self?.updateUploader(status: status, progress: progress)
        }
    }

    /// Updates upload progress according to uploader's state.
    ///
    /// - Parameters:
    ///    - uploader: Resource uploader.
    func updateUploader(status: MediaTaskStatus, progress: Float) {
        // Ignore uploader state changes if upload is not active step.
        guard isUploadingActiveStep else { return }

        guard !progress.isNaN else {
            updateCurrentStep(with: .failure)
            return
        }

        switch status {
        case .complete:
            updateCurrentStep(with: .success)
        case .error:
            updateCurrentStep(with: .failure)
        default:
            updateGlobalProgress(progress)
        }
    }

    /// Updates local panorama URL if a corresponding resource is present in drone's memory.
    /// A panorama generated on the device is stored using a local naming convention. It however needs to be updated if its corresponding resource
    /// has been uploaded on the drone (app needs to be able to inform user that the drone's pano resource is also present on the device or can be downloaded).
    func updateLocalPanoramaUrlIfNeeded() {
        guard isUploadingActiveStep,
              let localUrl = outputUrl,
              let media = media,
              let dronePanoResource = media.mediaResources?.first(where: { $0.type == .panorama }),
              let droneId = galleryMediaViewModel?.drone?.uid,
              let dstUrl = dronePanoResource.galleryURL(droneId: droneId, mediaType: media.type) else {
            return
        }

        MediaUtils.moveFile(srcUrl: localUrl, dstUrl: dstUrl)
        AssetUtils.shared.updateMediaInfoUrlInLocalList(srcUrl: localUrl, dstUrl: dstUrl)
        // Update outputUrl with new URL in order to be able to display immersive pano if needed.
        outputUrl = dstUrl
    }
}
