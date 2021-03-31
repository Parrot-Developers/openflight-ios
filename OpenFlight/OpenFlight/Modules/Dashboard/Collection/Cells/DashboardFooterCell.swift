// Copyright (C) 2020 Parrot Drones SAS
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

/// Custom View used for the footer of the Dashboard.
final class DashboardFooterCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var dataConfidentialityButton: UIButton!

    // MARK: - Internal Properties
    weak var coordinator: DashboardCoordinatorNavigation?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        updateView()
        // Debug tap gesture.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showParrotDebugScreen))
        tapGesture.numberOfTapsRequired = 3
        versionLabel.addGestureRecognizer(tapGesture)
    }
}

// MARK: - Actions
private extension DashboardFooterCell {
    @IBAction func dataConfidentialityButtonTouchedUpInside(_ sender: Any) {
        LogEvent.logAppEvent(itemName: LogEvent.LogKeyDashboardDataConfidentialityButton.dataConfidentiality.name,
                             logType: .simpleButton)
        coordinator?.startConfidentiality()
    }
}

// MARK: - Private Funcs
private extension DashboardFooterCell {
    /// Update text for version number and buttons.
    func updateView() {
        versionLabel.text = AppUtils.version
        dataConfidentialityButton.setTitle(L10n.dashboardFooterDataConfidentiality,
                                           for: .normal)
    }

    /// Shows the Parrot debug screen.
    @objc func showParrotDebugScreen() {
        LogEvent.logAppEvent(itemName: LogEvent.EventLoggerScreenConstants.debugLogs,
                             logType: .simpleButton)
        coordinator?.startParrotDebug()
    }
}
