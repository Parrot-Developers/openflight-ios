//
//  Copyright (C) 2021 Parrot Drones SAS.
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
import Reusable

/// Protocol used to handle full screen cell panorama actions.
protocol GalleryMediaFullScreenCellDelegate: AnyObject {
    func fullScreenCellDidTapShowImmersivePanorama()
    func fullScreenCellDidTapGeneratePanorama()
}

/// A model for the GalleryMediaFullScreenCollectionViewCell
struct GalleryMediaFullScreenCellModel {
    /// The url of the media to display.
    var url: URL?
    /// Whether media to display has a `Generate Panorama` button.
    var hasGeneratePanoramaButton = false
    /// Whether media to display can show an immersive panorama.
    var hasShowImmersivePanoramaButton = false
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
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView! // Exposed for zooming capability.
    @IBOutlet private weak var generatePanoramaButton: ActionButton!
    @IBOutlet private weak var showImmersivePanoramaButton: UIButton!

    // MARK: - Private Properties
    private var canGeneratePanorama: Bool {
        model?.hasGeneratePanoramaButton == true && !isLoading
    }
    private var canShowImmersivePanorama: Bool {
        model?.hasShowImmersivePanoramaButton == true && !isLoading
    }
    private var isLoading: Bool = true {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
            updateState()
        }
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
        generatePanoramaButton.isHidden = true
        showImmersivePanoramaButton.isHidden = true
        model = nil
        isLoading = true
        imageView.removeBlurEffect()
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
        setupView()

        displayImage(with: model?.url) { [weak self] image in
            self?.imageView.image = image
            self?.isLoading = false
        }
    }

    /// Sets up UI.
    func setupView() {
        generatePanoramaButton.model = ActionButtonModel(title: L10n.galleryGeneratePanorama,
                                             titleColor: .white,
                                             fontStyle: .big,
                                             backgroundColor: .warningColor)

        showImmersivePanoramaButton.cornerRadiusedWith(backgroundColor: .white, radius: Style.largeCornerRadius)

        isLoading = imageView.image == nil
        updateState()
    }

    /// Updates buttons state according to model.
    func updateState() {
        generatePanoramaButton.isHidden = !canGeneratePanorama

        showImmersivePanoramaButton.isHidden = !canShowImmersivePanorama
        if canGeneratePanorama {
            imageView.addBlurEffect()
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
