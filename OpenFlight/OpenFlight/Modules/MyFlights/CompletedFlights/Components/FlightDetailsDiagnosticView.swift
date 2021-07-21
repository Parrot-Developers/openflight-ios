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
import Reusable

// MARK: - Internal Structs
/// Model for `FlightDetailsDiagnosticView`.
struct FlightDetailsDiagnosticModel {
    var image: UIImage?
    var mainText: String?
    var subText: String?
    var supportButtonText: String?
    var supportURL: URL?
}

// MARK: - Protocols
/// Delegate for `FlightDetailsDiagnosticView`.
protocol FlightDetailsDiagnosticViewDelegate: AnyObject {
    /// Called to open an URL with user support.
    ///
    /// - Parameters:
    ///    - url: url of web page
    func openSupportURL(_ url: URL)
}

/// View that displays an issue in flight details.

final class FlightDetailsDiagnosticView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var mainLabel: UILabel!
    @IBOutlet private weak var subLabel: UILabel!
    @IBOutlet private weak var supportButton: UIButton!

    // MARK: - Internal Properties
    weak var delegate: FlightDetailsDiagnosticViewDelegate?
    var model: FlightDetailsDiagnosticModel? {
        didSet {
            fill()
        }
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitFlightDetailsDiagnosticView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitFlightDetailsDiagnosticView()
    }
}

// MARK: - Actions
private extension FlightDetailsDiagnosticView {
    @IBAction func supportButtonTouchedUpInside(_ sender: Any) {
        guard let url = model?.supportURL else {
            return
        }
        delegate?.openSupportURL(url)
    }
}

// MARK: - Private Funcs
private extension FlightDetailsDiagnosticView {
    /// Common init.
    func commonInitFlightDetailsDiagnosticView() {
        self.loadNibContent()
        self.cornerRadiusedWith(backgroundColor: ColorName.redTorch50.color,
                                radius: Style.mediumCornerRadius)
        mainLabel.makeUp()
        subLabel.makeUp(and: .white50)
        supportButton.makeup(with: .regular, color: .white)
        supportButton.cornerRadiusedWith(backgroundColor: UIColor.clear,
                                         borderColor: ColorName.white.color,
                                         radius: Style.largeCornerRadius,
                                         borderWidth: Style.mediumBorderWidth)
    }

    /// Fills up the view with its model.
    func fill() {
        mainLabel.text = model?.mainText
        subLabel.text = model?.subText
        subLabel.isHidden = model?.subText == nil
        supportButton.setTitle(model?.supportButtonText, for: .normal)
        imageView.image = model?.image
    }
}
