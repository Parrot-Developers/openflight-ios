//    Copyright (C) 2020 Parrot Drones SAS
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

final class FlightPlanCollectionViewCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var gradientView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var typeImage: UIImageView!
    @IBOutlet private weak var selectedView: UIView!
    @IBOutlet private weak var projectExecutedIcon: UIImageView!

    // MARK: - Private Enums
    private enum Constants {
        static let selectedItemBorderWidth = Style.selectedItemBorderWidth
        /// Gradient layer start alpha.
        static let gradientStartAlpha: CGFloat = 0.0
        /// Gradient layer end alpha.
        static let gradientEndAlpha: CGFloat = 0.65
    }

    // MARK: - Init
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
        dateLabel.makeUp(and: .greySilver)
        applyCornerRadius(Style.largeCornerRadius)
        selectedView.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: ColorName.highlightColor.color,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Constants.selectedItemBorderWidth)
        selectedView.isHidden = true
    }

    // MARK: - Internal Funcs
    /// Configure cell.
    ///
    /// - Parameters:
    ///     - project: project model
    ///     - isSelected: Whether cell is selected.
    func configureCell(project: ProjectModel, isSelected: Bool) {
        let lastExecution = project.lastExecution

        titleLabel.text = project.title ?? lastExecution?.dataSetting?.coordinate?.coordinatesDescription
        var date: Date = project.lastUpdated
        if let lastFlightExecutionDate = lastExecution?.lastFlightExecutionDate {
            date = lastFlightExecutionDate
        }
        dateLabel.text = date.commonFormattedString

        backgroundImageView.image = lastExecution?.thumbnail?.thumbnailImage ?? UIImage(asset: Asset.MyFlights.projectPlaceHolder)

        if project.type != FlightPlanMissionMode.standard.missionMode.flightPlanProvider?.projectType,
           let flightStoreProvider = getFligthPlanType(with: lastExecution?.type) {
            // Set image for custom Flight Plan types
            typeImage.image = flightStoreProvider.icon
            typeImage.isHidden = false
        } else {
            typeImage.image = nil
            typeImage.isHidden = true
        }

        projectExecutedIcon.isHidden = !project.hasExecutedProject()

        gradientView.backgroundColor = isSelected ? ColorName.white50.color : .clear
        selectedView.isHidden = !isSelected
    }

    private func getFligthPlanType(with type: String?) -> FlightPlanType? {
        return Services.hub.flightPlan.typeStore.typeForKey(type)
    }
}
