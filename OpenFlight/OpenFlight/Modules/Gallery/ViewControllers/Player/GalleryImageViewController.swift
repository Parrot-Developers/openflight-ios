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
import GroundSdk

// MARK: - Protocols
/// Gallery image ViewController Delegate.
protocol GalleryImageViewControllerDelegate: class {
    /// Notify delegate when media image index changes.
    ///
    /// - Parameters:
    ///     - index: Media index in the gallery media array
    func selectionDidChangeToImageIndex(_ index: Int)
}

/// Gallery image ViewController.

final class GalleryImageViewController: UIViewController, SwipableViewController {
    // MARK: - Outlets
    @IBOutlet private weak var scrollView: UIScrollView! {
        didSet {
            scrollView.minimumZoomScale = Constants.minZoom
            scrollView.maximumZoomScale = Constants.maxZoom
        }
    }
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var pickerSideView: UIView!
    @IBOutlet private weak var pickerView: UIPickerView!
    @IBOutlet private weak var pickerSelectionView: UIView!
    @IBOutlet private weak var generateSideView: UIView!
    @IBOutlet private weak var generateButton: UIButton!
    @IBOutlet private weak var generateFullScreenButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: GalleryImageViewControllerDelegate?
    private(set) var index: Int = 0

    // MARK: - Private Properties
    private weak var coordinator: GalleryCoordinator?
    private weak var viewModel: GalleryMediaViewModel?
    private var imageIndex: Int = 0
    private var imageUrl: URL?

    // MARK: - Private Enums
    private enum Constants {
        static let minZoom: CGFloat = 1.0
        static let maxZoom: CGFloat = 5.0
        static let pickerRowSize: CGFloat = 50.0
    }

    // MARK: - Setup
    /// Instantiate view controller.
    ///
    /// - Parameters:
    ///     - coordinator: gallery coordinator
    ///     - delegate: gallery image delegate
    ///     - viewModel: gallery view model
    ///     - index: Media index in the media array
    /// - Returns: a GalleryImageViewController.
    static func instantiate(coordinator: GalleryCoordinator?,
                            delegate: GalleryImageViewControllerDelegate?,
                            viewModel: GalleryMediaViewModel?,
                            index: Int) -> GalleryImageViewController {
        let viewController = StoryboardScene.GalleryMediaPlayerViewController.galleryImageViewController.instantiate()
        viewController.coordinator = coordinator
        viewController.delegate = delegate
        viewController.viewModel = viewModel
        viewController.index = index

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup interactions.
        photoImageView.isUserInteractionEnabled = true

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapOnImage))
        doubleTapGesture.numberOfTapsRequired = 2
        photoImageView.addGestureRecognizer(doubleTapGesture)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnImage))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.require(toFail: doubleTapGesture)
        photoImageView.addGestureRecognizer(tapGesture)

        setupDefaultImageIndex()
        setupPickerView()
        setupGenerateView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadImage()
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        setupPickerView()
        setupGenerateView()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension GalleryImageViewController {
    /// Single tap on image.
    @objc func tapOnImage() {
        viewModel?.toggleShouldHideControls()
    }

    /// Double tap on image.
    @objc func doubleTapOnImage() {
        /// Reset zoom.
        scrollView.zoomScale = Constants.minZoom
    }

    @IBAction func generateButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        let galleryPanoramaViewModel = GalleryPanoramaViewModel(galleryViewModel: viewModel)
        switch currentMedia.type {
        case .panoWide,
             .panoVertical,
             .panoHorizontal:
            coordinator?.showPanoramaQualityChoiceScreen(viewModel: galleryPanoramaViewModel, index: index)
        case .pano360:
            coordinator?.showPanoramaChoiceTypeScreen(viewModel: viewModel, index: index)
        default:
            return
        }
    }

    @IBAction func generateFullScreenButtonTouchedUpInside(_ sender: AnyObject) {
        guard let viewModel = viewModel,
              let media = viewModel.getMedia(index: index),
              let mediaUrls = media.urls,
              mediaUrls.count > imageIndex else {
            return
        }

        coordinator?.showPanoramaVisualisationScreen(viewModel: viewModel, url: mediaUrls[imageIndex])
    }
}

// MARK: - Private Funcs
private extension GalleryImageViewController {
    /// Load current image.
    func loadImage() {
        guard let media = viewModel?.getMedia(index: index) else { return }

        pickerView.isUserInteractionEnabled = false
        photoImageView.image = nil
        activityIndicator.startAnimating()
        viewModel?.getMediaPreviewImageUrl(media,
                                           imageIndex,
                                           completion: { [weak self] url in
                                            guard let url = url else { return }

                                            self?.pickerView.isUserInteractionEnabled = true
                                            self?.activityIndicator.stopAnimating()
                                            self?.displayImage(with: url)
                                           })
    }

    /// Display image.
    ///
    /// - Parameters:
    ///     - url: image url
    func displayImage(with url: URL?) {
        scrollView.zoomScale = Constants.minZoom
        guard let url = url else { return }

        imageUrl = url
        activityIndicator.startAnimating()
        switch url.pathExtension {
        case GalleryMediaType.photo.pathExtension:
            AssetUtils.shared.loadImage(withURL: url,
                                        compression: MediaConstants.defaultImageCompression) { [weak self] (_, image) in
                self?.activityIndicator.stopAnimating()
                self?.photoImageView.contentMode = .scaleAspectFit
                self?.photoImageView.image = image
                self?.setupPickerView()
                self?.setupGenerateView()
            }
        case GalleryMediaType.dng.pathExtension:
            AssetUtils.shared.loadRawImage(withURL: url) { [weak self] (_, image) in
                self?.activityIndicator.stopAnimating()
                self?.photoImageView.contentMode = .scaleAspectFit
                self?.photoImageView.image = image
                self?.setupPickerView()
                self?.setupGenerateView()
            }
        default:
            break
        }
    }

    /// Setup default image index.
    func setupDefaultImageIndex() {
        guard let viewModel = viewModel,
              let media = viewModel.getMedia(index: index) else {
            return
        }

        imageIndex = viewModel.getMediaImageDefaultIndex(media)
        delegate?.selectionDidChangeToImageIndex(imageIndex)
    }

    /// Setup picker view.
    func setupPickerView() {
        pickerSideView.removeBlurEffect()
        if traitCollection.verticalSizeClass == .compact {
            pickerSideView.addBlurEffect(with: .dark, cornerRadius: 0.0)
        }

        pickerSelectionView.layer.cornerRadius = Style.largeCornerRadius
        pickerSelectionView.layer.borderWidth = Style.mediumBorderWidth
        pickerSelectionView.layer.borderColor = ColorName.greenSpring.color.cgColor
        pickerSideView.isHidden = true
        pickerView.dataSource = self
        pickerView.selectRow(imageIndex, inComponent: 0, animated: false)
        pickerView.delegate = self
        pickerView.isUserInteractionEnabled = true
        pickerView.showsSelectionIndicator = false
        if let viewModel = viewModel,
           let media = viewModel.getMedia(index: index),
           viewModel.getMediaImageCount(media) > 1 {
            pickerSideView.isHidden = false
        }
    }

    /// Setup picker view.
    func setupGenerateView() {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        if UIApplication.isLandscape == false {
            generateSideView.isHidden = true
        } else {
            generateSideView.isHidden = viewModel.shouldHideGenerationOption(currentMedia: currentMedia)
            generateSideView.removeBlurEffect()
            generateSideView.addBlurEffect(with: .dark, cornerRadius: 0.0)
        }
        generateButton.makeup(with: .large, color: ColorName.white)
        generateButton.setTitle(L10n.galleryPanoramaGenerate, for: .normal)
        generateButton.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color, radius: Style.largeCornerRadius)
        generateFullScreenButton.cornerRadiusedWith(backgroundColor: ColorName.black60.color, radius: Style.largeCornerRadius)
        generateFullScreenButton.isHidden = true
        if let imageUrl = imageUrl {
            let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
            if panoramaRelatedEntries.contains(where: imageUrl.lastPathComponent.contains) {
                let matchingTerms = panoramaRelatedEntries.filter({ imageUrl.lastPathComponent.contains($0) })
                if let panoramaType = matchingTerms.first, panoramaType == PanoramaMediaType.sphere.rawValue {
                    generateFullScreenButton.isHidden = false
                }
            }
        }
    }
}

// MARK: - UIScrollView Delegate
extension GalleryImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let viewModel = viewModel,
              let currentMedia = viewModel.getMedia(index: index) else {
            return
        }

        pickerSideView.isHidden = scrollView.zoomScale != Constants.minZoom
        if UIApplication.isLandscape == false {
            generateSideView.isHidden = true
        } else {
            generateSideView.isHidden = viewModel.shouldHideGenerationOption(currentMedia: currentMedia)
                || scrollView.zoomScale != Constants.minZoom
        }
    }
}

// MARK: - UIPickerView Data source
extension GalleryImageViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach({
            $0.isHidden = $0.frame.height < 1.0
        })
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let viewModel = viewModel,
              let media = viewModel.getMedia(index: index) else {
            return 0
        }

        return viewModel.getMediaImageCount(media)
    }
}

// MARK: - UIPickerView Delegate
extension GalleryImageViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return Constants.pickerRowSize
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let viewModel = viewModel,
           let media = viewModel.getMedia(index: index) {
            let title = viewModel.getMediaImagePickerTitle(media, index: row)
            let panoramaRelatedEntries = PanoramaMediaType.allCases.map({ $0.rawValue })
            if panoramaRelatedEntries.contains(title) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.pickerRowSize, height: Constants.pickerRowSize))
                imageView.contentMode = .center
                switch title {
                case PanoramaMediaType.sphere.rawValue:
                    imageView.image = Asset.Gallery.Panorama.icSphere.image
                case PanoramaMediaType.tinyPlanet.rawValue:
                    imageView.image = Asset.Gallery.Panorama.icTinyPlanet.image
                case PanoramaMediaType.tunnel.rawValue:
                    imageView.image = Asset.Gallery.Panorama.icTunnel.image
                case PanoramaMediaType.horizontal.rawValue:
                    imageView.image = Asset.BottomBar.CameraSubModes.icPanoHorizontal.image
                case PanoramaMediaType.vertical.rawValue:
                    imageView.image = Asset.BottomBar.CameraSubModes.icPanoVertical.image
                case PanoramaMediaType.superWide.rawValue:
                    imageView.image = Asset.BottomBar.CameraSubModes.icPanoWide.image
                default:
                    imageView.image = Asset.Gallery.Panorama.customEdit.image
                }
                return imageView
            } else {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: Constants.pickerRowSize, height: Constants.pickerRowSize))
                label.textAlignment = .center
                label.makeUp(with: .large)
                label.text = title
                return label
            }
        }
        return UIView()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        imageIndex = row
        delegate?.selectionDidChangeToImageIndex(imageIndex)
        loadImage()
    }
}
