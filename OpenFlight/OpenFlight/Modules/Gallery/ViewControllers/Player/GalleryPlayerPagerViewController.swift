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

import UIKit

// MARK: - Protocols
/// Gallery Player Pager ViewController Delegate.
protocol GalleryPlayerPagerDelegate: AnyObject {
    /// Notify delegate when media changes.
    ///
    /// - Parameters:
    ///    - index: Media index in the gallery media array
    func galleryPagerDidChangeToIndex(_ index: Int)

    /// Notify delegate when media image index changes.
    ///
    /// - Parameters:
    ///     - index: Media index in the gallery media array
    func galleryPagerDidChangeToImageIndex(_ index: Int)
}

/// Protocol used to identify Gallery Player Pager ViewControllers.
protocol SwipableViewController {
    /// Page index.
    var index: Int { get }
}

/// Gallery Player Pager ViewController manages pagination between medias.

final class GalleryPlayerPagerViewController: UIPageViewController {
    // MARK: - Internal Properties
    weak var pagerDelegate: GalleryPlayerPagerDelegate?
    weak var coordinator: GalleryCoordinator?
    weak var viewModel: GalleryMediaViewModel?
    var index: Int = 0

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryPlayerPagerViewController.
    static func instantiate(coordinator: GalleryCoordinator,
                            viewModel: GalleryMediaViewModel,
                            index: Int) -> GalleryPlayerPagerViewController {
        let viewController = GalleryPlayerPagerViewController()
        viewController.coordinator = coordinator
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        guard let firstVC = pageViewController(atIndex: index) else { return }

        pagerDelegate?.galleryPagerDidChangeToIndex(index)
        setViewControllers([firstVC], direction: .forward, animated: false, completion: nil)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Private Funcs
private extension GalleryPlayerPagerViewController {
    /// Provides ViewController at index
    ///
    /// - Parameters:
    ///     - index: Media index in the gallery media array
    /// - Returns: UIViewController
    func pageViewController(atIndex index: Int) -> UIViewController? {
        guard let viewModel = viewModel,
            let media = viewModel.getMedia(index: index) else {
                return nil
        }

        switch media.type {
        case .video:
            return GalleryVideoViewController.instantiate(coordinator: coordinator,
                                                          viewModel: viewModel,
                                                          index: index)
        default:
            return GalleryImageViewController.instantiate(coordinator: coordinator,
                                                          delegate: self,
                                                          viewModel: viewModel,
                                                          index: index)
        }
    }
}

// MARK: - UIPageView Controller DataSource
extension GalleryPlayerPagerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let swipableVC = viewController as? SwipableViewController,
            swipableVC.index > 0 else {
                return nil
        }

        return self.pageViewController(atIndex: swipableVC.index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let swipableVC = viewController as? SwipableViewController,
            let viewModel = viewModel,
            swipableVC.index + 1 < viewModel.numberOfMedias else {
                return nil
        }

        return self.pageViewController(atIndex: swipableVC.index + 1)
    }
}

// MARK: - UIPageView Controller Delegate
extension GalleryPlayerPagerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        guard let currentViewController = pageViewController.viewControllers?.first as? SwipableViewController,
            let viewModel = viewModel,
            currentViewController.index < viewModel.numberOfMedias else {
                return
        }

        pagerDelegate?.galleryPagerDidChangeToIndex(currentViewController.index)
    }
}

// MARK: - GalleryImageViewController Delegate
extension GalleryPlayerPagerViewController: GalleryImageViewControllerDelegate {
    func selectionDidChangeToImageIndex(_ index: Int) {
        pagerDelegate?.galleryPagerDidChangeToImageIndex(index)
    }
}
