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

// MARK: - Protocols
protocol DashboardProfileCellDelegate: class {
    /// Starts login when connect button touched.
    func startLogin()
    /// Starts profile when user is connected.
    func startProviderProfile()
    /// Starts third party screen.
    ///
    /// - Parameters:
    ///    - service: third party service to start
    func startThirdPartyProcess(service: ThirdPartyService)
}

/// Profile cell for dashboard collection view.
final class DashboardProfileCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var userImageView: UIImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var userProfileView: UIView!
    @IBOutlet private weak var servicesView: UIView!
    @IBOutlet private weak var connectButton: UIButton!
    @IBOutlet private weak var profileButton: UIButton!
    @IBOutlet private weak var thirdPartyServicesStackView: UIStackView!

    // MARK: - Internal Properties
    weak var delegate: DashboardProfileCellDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        updateView()
        updateConnectionView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        updateConnectionView()
    }
}

// MARK: - Internal Funcs
extension DashboardProfileCell {
    /// Set cell content.
    ///
    /// - Parameters:
    ///    - icon: User image
    ///    - name: user name
    func setProfile(icon: UIImage?, name: String) {
        userImageView.image = icon
        userNameLabel.text = name
        updateConnectionView()
        updateThirdPartyButtons()
    }

    /// Set cell content for none connected user.
    func setNotConnected() {
        userImageView.image = nil
        userNameLabel.text = ""
        updateConnectionView()
        updateThirdPartyButtons()
    }
}

// MARK: - Actions
private extension DashboardProfileCell {
    @IBAction func connectButtonTouchedUpInside(_ sender: Any) {
        delegate?.startLogin()
    }

    @IBAction func profileButtonTouchedUpInside(_ sender: Any) {
        delegate?.startProviderProfile()
    }

    /// Called when a third party service button is tapped.
    ///
    /// - Parameters:
    ///    - sender: third party service's button
    @objc func thirdPartyServiceButtonTouchedUpInside(_ sender: DashboardServiceButton) {
        delegate?.startThirdPartyProcess(service: sender.service)
    }
}

// MARK: - Private Funcs
private extension DashboardProfileCell {
    /// Updates the view.
    func updateView() {
        self.connectButton.setTitle(L10n.commonLogIn, for: .normal)
        self.connectButton.makeup()
        self.connectButton.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                              radius: Style.smallCornerRadius)
        self.userProfileView.layer.cornerRadius = Style.largeCornerRadius
        self.userImageView.layer.cornerRadius = Style.smallCornerRadius
        self.userImageView.layer.masksToBounds = true
        self.servicesView.layer.cornerRadius = Style.largeCornerRadius
        setupThirdPartyButtons()
    }

    /// Updates view according to connection status.
    func updateConnectionView() {
        let isConnected: Bool = AccountManager.shared.currentAccount?.isConnected ?? false
        self.connectButton.isHidden = isConnected
        self.profileButton.isHidden = !isConnected
        self.userImageView.isHidden = !isConnected
        self.userNameLabel.isHidden = !isConnected
    }

    /// Sets up third party buttons.
    func setupThirdPartyButtons() {
        thirdPartyServicesStackView.safelyRemoveArrangedSubviews()

        guard let services = AccountManager.shared.currentAccount?.thirdPartyServices else { return }

        services.forEach {
            let button = DashboardServiceButton(frame: .zero,
                                                service: $0)
            button.addTarget(self,
                             action: #selector(thirdPartyServiceButtonTouchedUpInside(_:)),
                             for: .touchUpInside)
            thirdPartyServicesStackView.addArrangedSubview(button)
        }

        let fillerView = UIView()
        fillerView.backgroundColor = .clear
        thirdPartyServicesStackView.addArrangedSubview(fillerView)
    }

    /// Updates third party buttons accroding to their connection state.
    func updateThirdPartyButtons() {
        thirdPartyServicesStackView.arrangedSubviews
            .compactMap { $0 as? DashboardServiceButton }
            .forEach { $0.updateButton() }
    }
}

// MARK: - DashboardServiceButton
/// Button that displays a third party service in the cell.
final private class DashboardServiceButton: UIButton {
    // MARK: - Internal Properties
    let service: ThirdPartyService

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - frame: button's frame
    ///    - service: third party service to display
    init(frame: CGRect, service: ThirdPartyService) {
        self.service = service
        super.init(frame: frame)

        self.setImage(service.image, for: .normal)
        let constraint = self.heightAnchor.constraint(equalTo: self.widthAnchor,
                                                      multiplier: 1.0)
        self.addConstraint(constraint)
        self.updateButton()
    }

    required init?(coder: NSCoder) {
        fatalError("Should never init with coder")
    }

    // MARK: - Internal Funcs
    /// Updates button with connection state.
    func updateButton() {
        if service.isConnected {
            self.cornerRadiusedWith(backgroundColor: ColorName.greenSpring20.color,
                                    borderColor: ColorName.greenSpring.color,
                                    radius: Style.mediumCornerRadius,
                                    borderWidth: Style.mediumBorderWidth)
        } else {
            self.cornerRadiusedWith(backgroundColor: ColorName.white20.color,
                                    radius: Style.mediumCornerRadius)
        }
    }
}
