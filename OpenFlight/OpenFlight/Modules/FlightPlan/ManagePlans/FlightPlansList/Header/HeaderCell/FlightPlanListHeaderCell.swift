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

/// Struct Provider for `FlightPlanListHeaderCell` to contain all needed informations.
struct FlightPlanListHeaderCellProvider: Equatable {

    // MARK: - Init
    init(uuid: String, count: Int, missionType: String?, logo: UIImage?, isSelected: Bool) {
        self.uuid = uuid
        self.count = count
        self.missionType = missionType
        self.logo = logo
        self.isSelected = isSelected
    }

    var uuid: String
    var count: Int
    var missionType: String?
    var logo: UIImage?
    var isSelected: Bool
}

/// Cell of `FlightPlanListHeaderViewController` to display type of available kind of project.
class FlightPlanListHeaderCell: UICollectionViewCell, NibReusable {

    // MARK: - Outlets
    @IBOutlet weak var countLabel: UILabel! {
        didSet {
            countLabel.makeUp(and: .defaultTextColor)
        }
    }
    @IBOutlet weak var missionType: UILabel! {
        didSet {
            missionType.makeUp(and: .defaultTextColor)
        }
    }
    @IBOutlet private weak var logo: UIImageView!
    @IBOutlet private weak var bgView: UIView!

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        setupSelection(false)
    }

    // MARK: - Private Funcs
    /// Update selection of cell with changing colors of IBoutlet
    private func setupSelection(_ state: Bool) {
        let textColor = state ? .white : ColorName.defaultTextColor.color
        let backgroundColor = state ? ColorName.highlightColor.color : ColorName.white90.color
        bgView.backgroundColor = backgroundColor
        bgView.applyCornerRadius(Style.largeCornerRadius)
        countLabel.textColor = textColor
        missionType.textColor = textColor
        logo.tintColor = textColor
    }

    // MARK: - Public Funcs
    /// Configure cell properties.
    ///
    /// - Parameters:
    ///     - provider: cell configuration provider (count, logo, missionType)
    func configure(with provider: FlightPlanListHeaderCellProvider) {
        countLabel.text = "\(provider.count)"
        missionType.text = provider.missionType
        logo.image = provider.logo?.withRenderingMode(.alwaysTemplate)
        setupSelection(provider.isSelected)
    }
}
