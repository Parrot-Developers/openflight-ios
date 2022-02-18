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

final class FlightPlanListExecutionHeaderCell: MainTableViewCell, NibReusable {

    @IBOutlet private weak var cellStackView: MainContainerStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.makeUp(with: .large, and: .defaultTextColor)
        subtitleLabel.makeUp(with: .small, and: .defaultTextColor)
        backgroundView = UIView(frame: .zero)
        backgroundView?.backgroundColor = .clear
        backgroundColor = .clear

        // Setup margins
        cellStackView.directionalLayoutMargins = .init(top: Layout.mainSpacing(isRegularSizeClass),
                                                       leading: Layout.mainPadding(isRegularSizeClass),
                                                       bottom: Layout.mainSpacing(isRegularSizeClass),
                                                       trailing: Layout.mainPadding(isRegularSizeClass))
    }
}

extension FlightPlanListExecutionHeaderCell {

    func fill(project: ProjectModel, executions: Int) {
        titleLabel.text = project.title
        configure(executions: executions)
    }

    func fill(exeuctions: Int) {
        titleLabel.isHidden = true
        configure(executions: exeuctions)
    }

    private func configure(executions: Int) {
        subtitleLabel.text = executions <= 1
            ? L10n.dashboardMyFlightsProjectExecution(executions)
            : L10n.dashboardMyFlightsProjectExecutions(executions)
    }
}
