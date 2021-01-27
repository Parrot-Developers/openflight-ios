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

// MARK: - Protocols
/// Protocol for flight plan edition bottom bar's actions.
protocol FlightPlanEditionBottomBarViewControllerDelegate: class {
    /// Center map on user or drone.
    func centerMap()
    /// Show manage plans view.
    func showManagePlans()
    /// Show Flight Plan history.
    ///
    /// - Parameters:
    ///    - flightPlanViewModel: Flight Plan ViewModel
    func showHistory(flightPlanViewModel: FlightPlanViewModel?)
    /// Select settings button.
    func didTapSettingsButton()
    /// Undo to previous edition state.
    func didTapOnUndo()
}

/// Manages flight plan edition bottom bar.
final class FlightPlanEditionBottomBarViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var centerMapButton: UIControl!
    @IBOutlet private weak var managePlansButton: FlightPlanManageBarView!
    @IBOutlet private weak var settingsButton: UIControl!
    @IBOutlet private weak var undoButton: HighlightableUIControl! {
        didSet {
            undoButton.addBlurEffect()
        }
    }

    // MARK: - Internal Properties
    weak var delegate: FlightPlanEditionBottomBarViewControllerDelegate?
    var showUndo: Bool = false {
        didSet {
            undoButton?.isHidden = !showUndo
        }
    }
    var showSettingsButton: Bool = false {
        didSet {
            settingsButton?.isHidden = !showSettingsButton
        }
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        centerMapButton.addBlurEffect()
        managePlansButton.addBlurEffect()
        settingsButton.addBlurEffect()
        undoButton.isHidden = !showUndo
        settingsButton.isHidden = !showSettingsButton
        managePlansButton.delegate = self
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension FlightPlanEditionBottomBarViewController {
    @IBAction func centerMapButtonTouchedUpInside(_ sender: Any) {
        delegate?.centerMap()
    }

    @IBAction func settingsButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapSettingsButton()
    }

    @IBAction func undoButtonTouchedUpInside(_ sender: Any) {
        delegate?.didTapOnUndo()
    }
}

// MARK: - FlightPlanManageBarViewDelegate
extension FlightPlanEditionBottomBarViewController: FlightPlanManageBarViewDelegate {
    func managePlanTouchedUpInside() {
        delegate?.showManagePlans()
    }

    func historyTouchedUpInside(flightPlanViewModel: FlightPlanViewModel?) {
        delegate?.showHistory(flightPlanViewModel: flightPlanViewModel)
    }
}
