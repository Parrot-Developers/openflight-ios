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

import UIKit
import Combine
import Reusable

/// Protocol used to handle full screen cell panorama actions.
protocol GalleryMediaFullScreenCellDelegate: AnyObject {
    func fullScreenCellDidTapShowImmersivePanorama()
    func fullScreenCellDidTapGeneratePanorama()
    func fullScreenCellDidStartLoading()
    func fullScreenCellDidStopLoading()
    func fullScreenCellDidStartZooming()
    func fullScreenCellDidStopZooming()
}

/// A model for the GalleryMediaFullScreenCollectionViewCell
struct GalleryMediaFullScreenCellModel {
    /// The url of the media to display.
    var url: URL?
    /// Whether the cell is an additional panorama cell (used for generation).
    var isAdditionalPanoramaCell = false
    /// The panorama generation state.
    var panoramaGenerationState: PanoramaGenerationState
    /// Whether media to display can show an immersive panorama.
    var hasShowImmersivePanoramaButton = false
    /// the galleryMediaViewModel is used to update state on other downloads.
    var galleryMediaViewModel: GalleryMediaViewModel?
}

/// A class for displaying a full screen gallery media collectionView cell.
final class GalleryMediaFullScreenCollectionViewCell: UICollectionViewCell, NibReusable {
    var model: GalleryMediaFullScreenCellModel? {
        didSet {
            update()
        }
    }
    weak var delegate: GalleryMediaFullScreenCellDelegate?

    // MARK: - Outlets
    @IBOutlet private weak var loadingImageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var zoomableImageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var zoomableImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var generatePanoramaButton: ActionButton!
    @IBOutlet private weak var expectedResourcesErrorInfoView: MainBannerInfoView!
    @IBOutlet private weak var showImmersivePanoramaButton: UIButton!

    // MARK: - Private Enums
    private enum Constants {
        static let minZoom: CGFloat = 1.0
        static let maxZoom: CGFloat = 5.0
    }

    // MARK: - Private Properties
    private var previousUrl: String?
    private var canGeneratePanorama: Bool {
        model?.isAdditionalPanoramaCell == true && !isLoading
    }
    private var canShowImmersivePanorama: Bool {
        model?.hasShowImmersivePanoramaButton == true && !isLoading
    }
    private var isLoading: Bool = true {
        didSet {
            loadingImageView.isHidden = !isLoading
            if isLoading {
                loadingImageView.startRotate()
                delegate?.fullScreenCellDidStartLoading()
            } else {
                loadingImageView.stopRotate()
                delegate?.fullScreenCellDidStopLoading()
            }
            updateState()
        }
    }
    private var otherDownloadCancellable: AnyCancellable?
    private var otherDownloadRunning: Bool = false

    func updateZoomLevel(_ level: GalleryMediaBrowsingViewModel.ZoomLevel) {
        guard level != .custom else { return }

        UIView.animate(withDuration: Style.shortAnimationDuration) {
            let zoom = level == .maximum ? Constants.maxZoom : Constants.minZoom
            self.scrollView.zoomScale = zoom
        }
    }
}

// MARK: - Actions
internal extension GalleryMediaFullScreenCollectionViewCell {
    @IBAction func showImmersivePanoramaButtonTouchedUpInside(_ sender: Any) {
        delegate?.fullScreenCellDidTapShowImmersivePanorama()
    }

    @IBAction func generateButtonTouchedUpInside(_ sender: Any) {
        delegate?.fullScreenCellDidTapGeneratePanorama()
    }
}

// MARK: - Internal Funcs
internal extension GalleryMediaFullScreenCollectionViewCell {
    /// Updates view content according to model.
    func update() {
        if otherDownloadCancellable == nil, let viewModel = model?.galleryMediaViewModel {
            otherDownloadCancellable = viewModel.$downloadProgress
                .combineLatest(viewModel.$downloadStatus)
                .sink { (progress, status) in
                    self.otherDownloadRunning = status == .running && progress != nil
                }
        }
        if let previousUrl = previousUrl, previousUrl != model?.url?.absoluteString {
            imageView.image = nil
        }
        setupView()

        displayImage(with: model?.url) { [weak self] image in
            guard let self = self else { return }
            self.previousUrl = self.model?.url?.absoluteString
            self.imageView.image = image
            self.isLoading = false
        }
    }

    /// Sets up UI.
    func setupView() {
        let zoomable = model?.isAdditionalPanoramaCell != true
        scrollView.minimumZoomScale = Constants.minZoom
        scrollView.maximumZoomScale = zoomable ? Constants.maxZoom : Constants.minZoom
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
        generatePanoramaButton.model = ActionButtonModel(title: L10n.galleryGeneratePanorama,
                                                         fontStyle: .big,
                                                         style: .action1)

        showImmersivePanoramaButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)

        isLoading = imageView.image == nil
        expectedResourcesErrorInfoView.model = .init(icon: Asset.Gallery.mediaCorrupted.image,
                                                     iconTintColor: ColorName.errorColor.color,
                                                     title: L10n.galleryPanoramaGenerationErrorMissingPhotos)
        updateState()
    }

    /// Updates buttons state according to model.
    func updateState() {
        let shouldShowPanoramaGenerationError = canGeneratePanorama && model?.panoramaGenerationState == .missingResources
        expectedResourcesErrorInfoView.isHidden = !shouldShowPanoramaGenerationError
        generatePanoramaButton.isHidden = !canGeneratePanorama || model?.panoramaGenerationState != .toGenerate
        generatePanoramaButton.isEnabled = !otherDownloadRunning
        imageView.contentMode = canGeneratePanorama ? .scaleAspectFill : .scaleAspectFit

        showImmersivePanoramaButton.isHidden = !canShowImmersivePanorama
        if canGeneratePanorama {
            imageView.addBlurEffect(with: .systemThinMaterialDark)
        } else {
            imageView.removeBlurEffect()
        }
    }

    /// Loads image from url.
    func displayImage(with url: URL?, completion: @escaping (_ image: UIImage?) -> Void) {
        guard let url = url else { return }

        let loadImage: (URL, @escaping (UIImage?) -> Void) -> Void
        switch url.pathExtension {
        case GalleryMediaType.photo.pathExtension:
            loadImage = AssetUtils.shared.loadImage
        case GalleryMediaType.dng.pathExtension:
            loadImage = AssetUtils.shared.loadRawImage
        default:
            return
        }

        loadImage(url) { image in
            completion(image)
        }
    }
}

// MARK: - ScrollViewDelegate
extension GalleryMediaFullScreenCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.fullScreenCellDidStartZooming()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegate?.fullScreenCellDidStopZooming()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = imageView.image {
                let ratioW = imageView.frame.width / image.size.width
                let ratioH = imageView.frame.height / image.size.height
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth * scrollView.zoomScale > imageView.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - imageView.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditionTop = newHeight * scrollView.zoomScale > imageView.frame.height
                let top = 0.5 * (conditionTop ? newHeight - imageView.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
}

public class ZoomOnlyScrollView: UIScrollView {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if zoomScale == 1
            || gestureRecognizer.view == self
            || gestureRecognizer is UITapGestureRecognizer {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        return false
    }
}
