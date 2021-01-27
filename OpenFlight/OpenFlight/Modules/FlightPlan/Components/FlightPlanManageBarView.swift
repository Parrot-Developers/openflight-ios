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

// MARK: - FlightPlanManageBarViewDelegate
/// Delegate protocol for FlightPlanManageBarView.
protocol FlightPlanManageBarViewDelegate: class {
    /// Function called when user touch the Flight Plan name view.
    func managePlanTouchedUpInside()
    /// Function called when user touch the history view.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan ViewModel which history is related
    func historyTouchedUpInside(flightPlanViewModel: FlightPlanViewModel?)
}

// MARK: - FlightPlanManageBarView
/// Displays current flight plan's name in a bottom bar.
/// Used as a button to access flight plan managing screens.
final public class FlightPlanManageBarView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var nameView: HighlightableUIControl!
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .tiny, and: .white50)
            titleLabel.text = L10n.commonFlightPlan.uppercased()
        }
    }
    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            nameLabel.makeUp()
            nameLabel.text = L10n.flightPlanNewProject
        }
    }
    @IBOutlet private weak var arrowView: SimpleArrowView! {
        didSet {
            arrowView.orientation = .bottom
        }
    }
    @IBOutlet private weak var historyView: HighlightableUIControl!

    // MARK: - Public Properties
    var flightPlanName: String? {
        didSet {
            // Reset flight plan name to default value if flightPlanName is nil.
            nameLabel.text = flightPlanName ?? L10n.flightPlanNewProject
        }
    }
    weak var delegate: FlightPlanManageBarViewDelegate?

    // MARK: - Private Properties
    private var flightPlanListener: FlightPlanListener?
    private var flightPlanViewModel: FlightPlanViewModel?
    private var hasHistory: Bool {
        return flightPlanViewModel?.executions.isEmpty == false
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitFlightPlanManageBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitFlightPlanManageBarView()
    }

    // MARK: - Deinit
    deinit {
        self.removeTargets()
        FlightPlanManager.shared.unregister(self.flightPlanListener)
    }

    // MARK: - Public Funcs
    /// Set selected display.
    ///
    /// - Parameters:
    ///     - isSelected: is selected
    func setSelectedDisplay(isSelected: Bool = true) {
        self.historyView.isHidden = isSelected ? true : !self.hasHistory
        arrowView.orientation = isSelected ? .top : .bottom
        addBlurEffect()
        let backgroundColor = isSelected ? ColorName.greenSpring20.color : .clear
        let borderColor = isSelected ? ColorName.greenSpring.color : .clear
        cornerRadiusedWith(backgroundColor: backgroundColor,
                           borderColor: borderColor,
                           radius: Style.largeCornerRadius,
                           borderWidth: Style.largeBorderWidth)
    }
}

// MARK: - Private Funcs
private extension FlightPlanManageBarView {
    /// Common init.
    func commonInitFlightPlanManageBarView() {
        self.loadNibContent()
        self.setupFlightPlanListener()
        self.addTargets()
    }

    /// Add a target when user touch the view.
    func addTargets() {
        self.nameView.addTarget(self, action: #selector(managePlanTouchedUpInside), for: .touchUpInside)
        self.historyView.addTarget(self, action: #selector(historyViewTouchedUpInside), for: .touchUpInside)
    }

    /// Remove the target when user touch the view.
    func removeTargets() {
        self.nameView.removeTarget(self, action: #selector(managePlanTouchedUpInside), for: .touchUpInside)
        self.historyView.removeTarget(self, action: #selector(historyViewTouchedUpInside), for: .touchUpInside)
    }

    /// Setup FlightPlan listener.
    func setupFlightPlanListener() {
        flightPlanListener = FlightPlanManager.shared.register(didChange: { [weak self] flightPlan in
            self?.update(flightPlanViewModel: flightPlan)
        })
    }

    /// Update flight plan name in the widget.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: view model for the selected flight plan
    func update(flightPlanViewModel: FlightPlanViewModel?) {
        self.flightPlanViewModel = flightPlanViewModel
        self.flightPlanName = flightPlanViewModel?.state.value.title
        self.historyView.isHidden = !self.hasHistory
    }
}

// MARK: - Actions
private extension FlightPlanManageBarView {
    @objc func managePlanTouchedUpInside() {
        self.delegate?.managePlanTouchedUpInside()
    }

    @objc func historyViewTouchedUpInside() {
        self.delegate?.historyTouchedUpInside(flightPlanViewModel: flightPlanViewModel)
    }
}
