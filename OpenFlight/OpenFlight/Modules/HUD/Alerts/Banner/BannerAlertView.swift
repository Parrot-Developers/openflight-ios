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

/// A view model for a banner alert view.
struct BannerAlertViewModel {
    /// The banner alert view content.
    let content: BannerAlertContent
    /// The banner alert view style.
    let style: BannerAlertStyle
}

/// A banner alert view.
class BannerAlertView: UIView {
    /// The view model.
    var viewModel: BannerAlertViewModel! {
        didSet { updateView() }
    }

    // MARK: Private properties

    /// The content stack view.
    private let stackView = BackgroundStackView()
    /// The image view for banner alert icon.
    private let imageView = UIImageView()
    /// The label for banner alert title.
    private let label = UILabel()

    // MARK: Init

    /// Constructor.
    ///
    /// - Parameter viewModel: the banner alert view model
    convenience init(viewModel: BannerAlertViewModel) {
        self.init()

        setupView()
        self.viewModel = viewModel
        updateView()
    }
}

// MARK: - Private

private extension BannerAlertView {
    /// Sets up view.
    func setupView() {
        // Content stack view.
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = BannerAlertConstants.defaultPadding
        stackView.insetsLayoutMarginsFromSafeArea = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.cornerRadius = Style.mediumCornerRadius

        // Image and label.
        imageView.contentMode = .scaleAspectFit
        label.numberOfLines = 0
        label.textAlignment = .center
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.makeUp(with: .large)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        addSubview(stackView)

        // Add constraints.
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let iconHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: BannerAlertConstants.iconMaxSize)
        iconHeightConstraint.priority = .defaultHigh
        iconHeightConstraint.isActive = true
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualToConstant: BannerAlertConstants.iconMaxSize),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -BannerAlertConstants.defaultSpacing)
        ])
    }

    /// Updates view according to view model.
    func updateView() {
        let hPadding = viewModel.style.hPadding ?? BannerAlertConstants.defaultPadding
        let vPadding = viewModel.style.vPadding ?? BannerAlertConstants.compactPadding
        stackView.layoutMargins = .init(top: vPadding, left: hPadding, bottom: vPadding, right: hPadding)
        imageView.image = viewModel.content.icon
        imageView.isHidden = viewModel.content.icon == nil
        label.text = viewModel.content.title
        stackView.backgroundColor = viewModel.style.backgroundColor
        imageView.tintColor = viewModel.style.iconColor
        label.textColor = viewModel.style.titleColor
    }
}
