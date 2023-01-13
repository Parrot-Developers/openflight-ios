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

import Combine

protocol MediaContainer {
    var media: GalleryMedia { get }
}

/// Gallery Player Pager ViewController manages pagination between medias.

final class MediaPagerViewController: UIPageViewController {

    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    /// The browser manager.
    private var browserManager: MediaBrowserManager!
    /// The stream replay service.
    private var streamReplayService: StreamReplayService { browserManager.mediaServices.streamReplayService }
    /// The camera recording service.
    private var cameraRecordingService: CameraRecordingService { browserManager.cameraRecordingService }
    /// The media to be displayed after transition is completed.
    private var nextMedia: GalleryMedia?

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameter browserManager: the browser manager
    /// - Returns: a `MediaPagerViewController`
    static func instantiate(browserManager: MediaBrowserManager) -> MediaPagerViewController {
        let viewController = MediaPagerViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        viewController.browserManager = browserManager

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self
        setContainer(media: browserManager.activeFilteredMedia)

        // Set page controller scroll view delegate in order to grab didScroll events.
        let scrollView = view.subviews.filter { $0 is UIScrollView }.first as? UIScrollView
        scrollView?.delegate = self

        browserManager.activeMediaDidChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] media in
            self?.setContainer(media: media)
        }
        .store(in: &cancellables)
    }

    /// Sets active container according to provided media.
    ///
    /// - Parameter media: the media to load
    func setContainer(media: GalleryMedia?) {
        guard let media = media else {
            browserManager.noMediaToBrowse()
            return
        }

        setViewControllers([mediaContainer(for: media)], direction: .forward, animated: false, completion: nil)
    }
}

// MARK: - Private Funcs
private extension MediaPagerViewController {

    /// Returns photo viewer or video player controller for a specific `GalleryMedia`.
    ///
    /// - Parameter media: the media
    /// - Returns: the media container controller
    func mediaContainer(for media: GalleryMedia) -> UIViewController {

        switch media.type {
        case .video:
            return VideoPlayerViewController.instantiate(viewModel: VideoPlayerViewModel(streamReplayService: streamReplayService,
                                                                                         cameraRecordingService: cameraRecordingService,
                                                                                         mediaStoreService: browserManager.mediaServices.mediaStoreService,
                                                                                         media: media),
                                                         browserManager: browserManager)
        default:
            return PhotoViewerViewController.instantiate(viewModel: PhotoViewerViewModel(mediaListService: browserManager.mediaServices.mediaListService,
                                                                                         media: media),
                                                         browserManager: browserManager)
        }
    }
}

// MARK: - UIPageView Controller DataSource
extension MediaPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let mediaBefore = browserManager.filteredMediaBefore(media: (viewController as? MediaContainer)?.media) else { return nil }
        return mediaContainer(for: mediaBefore)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let mediaAfter = browserManager.filteredMediaAfter(media: (viewController as? MediaContainer)?.media) else { return nil }
        return mediaContainer(for: mediaAfter)
    }
}

extension MediaPagerViewController: UIPageViewControllerDelegate, UIScrollViewDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        // Store next media to be displayed after transition is completed in order to update parent media info before
        // VC is actually presented.
        nextMedia = (pendingViewControllers.first as? MediaContainer)?.media
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let activeMedia = (viewControllers?.first as? MediaContainer)?.media else { return }

        let offsetX = scrollView.contentOffset.x
        let width = scrollView.frame.width
        let percent = round(abs(offsetX - width) / width)

        if percent >= 0.5 {
            // Scrolled beyond halfway => set active info to next media (if any).
            browserManager.setActiveMedia(nextMedia ?? activeMedia)
        } else {
            browserManager.setActiveMedia(activeMedia)
        }

        // Show controls during scroll in order to start auto-hide timer after release.
        browserManager.showControls()
    }
}
