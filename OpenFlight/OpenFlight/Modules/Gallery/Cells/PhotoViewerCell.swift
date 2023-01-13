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

import Combine
import Reusable

/// A delegate to inform of cell user interaction.
protocol PhotoViewerCellDelegate: AnyObject {

    /// Reports a show immersive panorama request.
    func didTapShowImmersivePanorama()
    /// Reports a generate panorama request.
    func didTapGeneratePanorama()
    /// Reports a zooming start.
    func didStartZooming()
    /// Reports a zooming end at a specific level.
    ///
    /// - Parameter level: the level of the zoom
    func didStopZooming(at level: PhotoViewerZoomLevel)
}

/// A cell type.
enum PhotoViewerCellType {

    /// Generated immersive panorama (360).
    case immersivePano
    /// Panorama to be generated (can be invalid).
    case panoGen(isValid: Bool)
    /// Generic photo (can be a generated panorama).
    case photo

    /// The image view content mode.
    var imageContentMode: UIView.ContentMode {
        switch self {
        case .panoGen: return .scaleAspectFill
        default: return .scaleAspectFit
        }
    }

    /// Whether image view is blurred.
    var isBlurred: Bool {
        switch self {
        case .panoGen: return true
        default: return false
        }
    }
}

/// A model for the photo viewer cell.
struct PhotoViewerCellModel {

    /// The image url.
    var url: URL?
    /// The type of the cell.
    var type: PhotoViewerCellType = .photo
    /// Whether the cell is loading.
    var isLoading = true

    /// The panorama generation button state according to type.
    var panoGenButtonState: (isHidden: Bool, isEnabled: Bool) {
        if case .panoGen(let isValid) = type {
            return (isHidden: false, isEnabled: isValid)
        }
        return (isHidden: true, isEnabled: false)
    }

    /// Whether the cell is an invalid panorama.
    var isInvalidPanoGen: Bool {
        if case .panoGen(let isValid) = type, !isValid {
            return true
        }
        return false
    }

    /// Whether zoom is enabled on cell's image.
    var isZoomEnabled: Bool {
        if case .panoGen = type { return false }
        return true
    }
}

/// A class for displaying a full screen gallery media collectionView cell.
final class PhotoViewerCell: UICollectionViewCell, NibReusable {

    /// The cell model.
    var model = PhotoViewerCellModel() {
        didSet { configure(model: model) }
    }
    /// The interaction delegate.
    weak var delegate: PhotoViewerCellDelegate?

    // MARK: - Outlets
    @IBOutlet private weak var loadingImageView: UIImageView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var generatePanoramaButton: ActionButton!
    @IBOutlet private weak var bannerAlertView: BannerAlertView!
    @IBOutlet private weak var bannerAlertViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var expectedResourcesErrorInfoView: MainBannerInfoView!
    @IBOutlet private weak var showImmersivePanoramaButton: UIButton!
    @IBOutlet private weak var showImmersiveButtonTrailingConstraint: NSLayoutConstraint!

    // MARK: - Private Enums
    private enum Constants {
        static let minZoom: CGFloat = 1.0
        static let maxZoom: CGFloat = 4.0
    }

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForReuse() {
        imageView.image = nil
    }

    /// Configures the view according to a specific model.
    ///
    /// - Parameter model: the model to configure the view to
    func configure(model: PhotoViewerCellModel) {
        // Image view.
        imageView.contentMode = model.type.imageContentMode
        if model.type.isBlurred {
            imageView.addBlurEffect(with: .systemThinMaterialDark)
        } else {
            imageView.removeBlurEffect()
        }
        // Set image if URL is already known.
        if let url = model.url {
            imageView.image = AssetUtils.loadImage(url: url)
        }

        generatePanoramaButton.isHidden = model.panoGenButtonState.isHidden
        generatePanoramaButton.isEnabled = model.panoGenButtonState.isEnabled
        bannerAlertView.isHidden = !model.isInvalidPanoGen
        scrollView.pinchGestureRecognizer?.isEnabled = model.isZoomEnabled

        // Immersive panorama button.
        if case .immersivePano = model.type {
            showImmersivePanoramaButton.isHidden = false
        } else {
            showImmersivePanoramaButton.isHidden = true
        }
    }

    /// Configures the view with a specific image.
    ///
    /// - Parameter image: the image to set
    func configure(image: UIImage?) {
        imageView.image = image
        model.isLoading = false
    }

    /// Zooms image to a specific level.
    ///
    /// - Parameter level: the level to zoom to
    func zoom(to level: PhotoViewerZoomLevel) {
        guard level != .custom else { return }

        UIView.animate {
            self.scrollView.zoomScale = level == .maximum ? Constants.maxZoom : Constants.minZoom
        }
    }

    /// Shows/hides controls according to provided parameter.
    ///
    /// - Parameter show: whether the controls should be shown
    func showControls(_ show: Bool) {
        showImmersivePanoramaButton.showFromEdge(.right,
                                                 offset: showImmersiveButtonTrailingConstraint.constant,
                                                 show: show)
    }
}

// MARK: - Actions
internal extension PhotoViewerCell {
    @IBAction func showImmersivePanoramaButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapShowImmersivePanorama()
    }

    @IBAction func generateButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapGeneratePanorama()
    }
}

private extension PhotoViewerCell {

    /// Sets up view.
    func setupView() {
        loadingImageView.startRotate()
        generatePanoramaButton.model = ActionButtonModel(title: L10n.galleryGeneratePanorama,
                                                         fontStyle: .big,
                                                         style: .action1)

        bannerAlertViewTopConstraint.constant = Layout.hudTopBarHeight(isRegularSizeClass) + Layout.mainSpacing(isRegularSizeClass)
        bannerAlertView.viewModel = .init(content: .init(icon: Asset.Gallery.mediaCorrupted.image,
                                                         title: L10n.galleryPanoramaGenerationErrorMissingPhotos),
                                          style: .init(iconColor: ColorName.errorColor.color,
                                                       titleColor: .white,
                                                       backgroundColor: ColorName.black60.color))

        showImmersivePanoramaButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)
        scrollView.minimumZoomScale = Constants.minZoom
        scrollView.maximumZoomScale = Constants.maxZoom
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.delegate = self
    }
}

// MARK: - ScrollViewDelegate
extension PhotoViewerCell: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // Return `nil` if zoom is disabled (panoGen cell) in order to avoid unwanted double-tap zoom triggering.
        model.isZoomEnabled ? imageView : nil
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegate?.didStartZooming()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let level: PhotoViewerZoomLevel
        switch scrollView.zoomScale {
        case Constants.maxZoom: level = .maximum
        case Constants.minZoom: level = .minimum
        default: level = .custom
        }
        delegate?.didStopZooming(at: level)
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
