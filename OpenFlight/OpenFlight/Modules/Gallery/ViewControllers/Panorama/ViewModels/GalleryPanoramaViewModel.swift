//
//  Copyright (C) 2020 Parrot Drones SAS.
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
    private var isDownloadingActiveStep: Bool {
        guard currentStepIndex < generationStepModels.count else { return false }

        switch generationStepModels[currentStepIndex].step {
        case .download: return true
        default: return false
        }
    }

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
        listenToMedia()
    }

    /// Sets up panorama generation steps according to sourceType/mediaType.
    func setupSteps() {
        guard let galleryMediaViewModel = galleryMediaViewModel,
              let sourceType = galleryMediaViewModel.sourceType,
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
                (.generate(panoramaType), generatePanorama)
            ]

            // Insert donwload step @0 if needed (if media has not been downloaded yet).
            if media?.downloadState == .toDownload {
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
    func listenToMedia() {
        mediaListener = galleryMediaViewModel?.registerListener { [weak self] state in
            // Ensure that active step is .download, as we may get progress updates from download
            // while step has already been completed (success received from galleryMediaViewModel.downloadMedias.
            guard let self = self,
                  self.isDownloadingActiveStep else {
                return
            }

            self.updateMediaProgress(state: state)
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

        guard generationStepModels
                .filter({ $0.status == .success })
                .count != generationStepModels.count else {
            // All steps have been finished => complete process.
            completeFullProcess()
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

    func completeFullProcess() {
        galleryMediaViewModel?.refreshMedias(source: media?.source)
        galleryMediaViewModel?.refreshMedias(source: .mobileDevice)
        DispatchQueue.main.async {
            // Notify browsingVM of panorama completion for gallery refresh.
            self.galleryMediaViewModel?.mediaBrowsingViewModel.didUpdatePanoramaGeneration(.success)
        }

        if galleryMediaViewModel?.state.value.sourceType == .mobileDevice {
            // Panorama has been generated from local memory.
            // => Only have to check if immersive sphere pano screen needs to be opened.
            if media?.type.toPanoramaType == .sphere {
                showPanoramaVisualisationScreenAndDismiss(viewModel: galleryMediaViewModel)
            } else {
                dismiss()
            }
        } else {
            // Panorama has been generated from drone's memory.
            // => Switch to device's storage as upload is not available yet.
            showPanoramaFromDeviceStorageAndDismiss()
        }
    }

    func showPanoramaVisualisationScreenAndDismiss(viewModel: GalleryMediaViewModel?, delay: TimeInterval = Style.shortAnimationDuration) {
        guard let viewModel = viewModel,
              let url = self.outputUrl else {
            return
        }

        coordinator?.showPanoramaVisualisationScreen(viewModel: viewModel, url: url)
        dismiss(delay: delay)
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
            self.coordinator?.dismissPanoramaGenerationScreen()
            self.generationStepModels.removeAll()
        }
    }
}

// MARK: - Media Download
private extension GalleryPanoramaViewModel {
    func updateMediaProgress(state: GalleryMediaState) {
        guard state.downloadStatus == .running || state.downloadStatus == .error else {
            return
        }

        if state.downloadStatus == .error {
            // Keep current progress when .failure rises.
            // Update status and exit.
            updateCurrentStep(with: .failure)
            return
        }

        updateGlobalProgress(Float(state.downloadProgress))
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
              let mediaPrefix = mediaFromDevice.url?.prefix else {
            return
        }

        let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
        let inputs = mediaUrls.filter({!panoramaRelatedEntries.contains(where: $0.lastPathComponent.contains)})
        let width: Int32 = type.width(forQuality: panoramaQuality)
        let height: Int32 = type.height(forQuality: panoramaQuality)
        outputUrl = URL(string: String(mediaFolderPath + mediaPrefix + "-" + type.rawValue + ".JPG"))

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
    /// Shows generated panorama from device's storage.
    /// Function will be removed when upload feature is available.
    func showPanoramaFromDeviceStorageAndDismiss() {
        galleryMediaViewModel?.state.value.sourceType = .mobileDevice
        coordinator?.backToRoot()

        guard let viewModel = galleryMediaViewModel,
              let mediaFromDevice = mediaFromDevice else {
            return
        }

        DispatchQueue.main.async {
            guard let index = self.galleryMediaViewModel?.getMediaIndex(mediaFromDevice) else {
                return
            }

            self.coordinator?.showMediaPlayer(viewModel: viewModel, index: index)

            if mediaFromDevice.type.toPanoramaType == .sphere {
                self.showPanoramaVisualisationScreenAndDismiss(viewModel: viewModel, delay: Style.longAnimationDuration)
            } else {
                self.dismiss(delay: Style.longAnimationDuration)
            }
        }
    }

    func uploadMedia() {
        // TODO: Add upload feature.
    }

    /// Delete current media.
    func deleteCurrentMedia() {
        guard let currentMedia = media else { return }

        galleryMediaViewModel?.deleteMedias([currentMedia]) { [weak self] success in
            guard success else { return }

            self?.galleryMediaViewModel?.refreshMedias()
        }
    }
}
