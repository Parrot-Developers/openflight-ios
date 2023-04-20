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
import Reusable
import Combine

class ProjectCollectionViewCell: UICollectionViewCell, NibReusable {

    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var typeImage: UIImageView!
    @IBOutlet private weak var selectedView: UIView!
    @IBOutlet private weak var projectExecutedIcon: UIImageView!

    enum Constants {
        static let selectedItemBorderWidth = Style.selectedItemBorderWidth
        static let gradientStartAlpha: CGFloat = 0.0
        static let gradientEndAlpha: CGFloat = 0.65
        static let defaultThumbnail = Asset.MyFlights.projectPlaceHolder.image
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        gradientView.addGradient(startAlpha: Constants.gradientStartAlpha,
                                 endAlpha: Constants.gradientEndAlpha,
                                 superview: self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        selectedView.isHidden = true
        projectExecutedIcon.isHidden = true
    }

    func setupUI() {
        titleLabel.makeUp()
        descriptionLabel.makeUp(and: .greySilver)
        applyCornerRadius(Style.largeCornerRadius)
        selectedView.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: ColorName.highlightColor.color,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Constants.selectedItemBorderWidth)
        selectedView.isHidden = true
    }

    func configureCell(_ model: ProjectCellModel) {
        backgroundImageView.image = model.thumbnail ?? Constants.defaultThumbnail
        titleLabel.text = model.title
        descriptionLabel.text = model.date
        typeImage.image = model.icon
        selectedView.isHidden = !model.isSelected
        projectExecutedIcon.isHidden = !model.isExecuted
        gradientView.backgroundColor = model.isSelected ? ColorName.white50.color : .clear
      }
}
