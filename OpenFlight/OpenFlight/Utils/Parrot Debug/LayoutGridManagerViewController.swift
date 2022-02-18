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

class LayoutGridManagerViewController: UIViewController {
    private var model: LayoutGridModel { LayoutGridModel.shared }

    // MARK: - Outlets
    @IBOutlet weak var leftPanelTitle: UILabel!
    @IBOutlet weak var leftPanelButton1: ActionButton!
    @IBOutlet weak var leftPanelButton2: ActionButton!
    @IBOutlet weak var leftPanelButton3: ActionButton!
    @IBOutlet weak var leftPanelButton4: ActionButton!

    @IBOutlet weak var rightPanelButton1: ActionButton!
    @IBOutlet weak var rightPanelButton2: ActionButton!
    @IBOutlet weak var rightPanelButton3: ActionButton!
    @IBOutlet weak var rightPanelButton4: ActionButton!
    @IBOutlet weak var rightPanelButton5: ActionButton!
    @IBOutlet weak var rightPanelButton6: ActionButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    // Controls
    @IBOutlet private weak var gridEnablingButton: ActionButton!
    @IBOutlet private var gridControls: [UIView]!
    @IBOutlet private weak var topBarModeSegmentedControl: UISegmentedControl!
    @IBOutlet private weak var topAreaButton: ActionButton!
    @IBOutlet private weak var leftPanelButton: ActionButton!
    @IBOutlet private weak var centerGuidesButton: ActionButton!
    @IBOutlet private weak var rightPanelButton: ActionButton!
    @IBOutlet private weak var bottomPanelButton: ActionButton!

    // MARK: - Private Properties
    private weak var coordinator: LayoutGridManagerCoordinator?

    // MARK: - Init
    static func instantiate(coordinator: LayoutGridManagerCoordinator) -> LayoutGridManagerViewController {
        let viewController = StoryboardScene.LayoutGridManager.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Enable grid by default.
        model.toggleVisibleState(forceIsShown: true)
        updateGridVisibility()
    }
}

private extension LayoutGridManagerViewController {
    func setupView() {
        overrideUserInterfaceStyle = .light

        leftPanelTitle.makeUp(and: ColorName.defaultTextColor)
        leftPanelTitle.text = L10n.missionSelectLabel.uppercased()

        leftPanelButton1.setup(image: Asset.MissionModes.icClassicMissionMode.image,
                               title: L10n.missionClassic,
                               style: .default1,
                               alignment: .left)
        leftPanelButton2.setup(image: FlightPlanMissionMode.standard.icon,
                               title: L10n.commonFlightPlan,
                               style: .validate,
                               alignment: .left)
        leftPanelButton3.setup(image: Asset.MissionModes.MissionSubModes.icCameramanMode.image,
                               title: "Cameraman",
                               style: .default1,
                               alignment: .left)
        leftPanelButton4.setup(image: Asset.MissionModes.MissionSubModes.icTouchFlyMode.image,
                               title: "Vehicule",
                               style: .default1,
                               alignment: .left)

        rightPanelButton1.setup(title: L10n.flightPlanNew, style: .validate)
        rightPanelButton2.setup(title: L10n.commonDelete, style: .destructive)
        rightPanelButton3.setup(title: L10n.flightPlanDuplicate, style: .default1)

        rightPanelButton4.setup(image: Asset.Common.Icons.play.image, style: .validate)
        rightPanelButton5.setup(image: Asset.Common.Icons.stop.image, style: .destructive)
        rightPanelButton6.setup(image: Asset.MyFlights.history.image, style: .default1)

        segmentedControl.customMakeup()
        segmentedControl.selectedSegmentIndex = 0

        topBarModeSegmentedControl.selectedSegmentIndex = model.topBarMode.rawValue
        updateGridVisibility()
        updateControls()
    }

    func updateGridVisibility() {
        let enablingIcon = model.isShown ? UIImage(systemName: "rectangle.split.3x3.fill") : UIImage(systemName: "rectangle.split.3x3")
        let enablingStyle = model.isShown ? ActionButtonStyle.validate : ActionButtonStyle.default2
        gridEnablingButton.setup(image: enablingIcon, style: enablingStyle)

        _ = gridControls.map { $0.animateIsHiddenInStackView(!model.isShown) }
    }

    func updateControls() {
        topBarModeSegmentedControl.animateIsHiddenInStackView(!model.hasTopBarArea)

        let activeStyle = ActionButtonStyle.default1
        let inactiveStyle = ActionButtonStyle.default2
        topAreaButton.setup(image: .init(systemName: "rectangle.topthird.inset"),
                            style: model.hasTopBarArea ? activeStyle : inactiveStyle)
        leftPanelButton.setup(image: .init(systemName: "rectangle.lefthalf.inset.fill"),
                              style: model.hasLeftPanelArea ? activeStyle : inactiveStyle)
        centerGuidesButton.setup(image: .init(systemName: "squareshape.split.2x2.dotted"),
                                 style: model.hasCenterGuides ? activeStyle : inactiveStyle)
        rightPanelButton.setup(image: .init(systemName: "rectangle.righthalf.inset.fill"),
                               style: model.hasRightPanelArea ? activeStyle : inactiveStyle)
        bottomPanelButton.setup(image: .init(systemName: "rectangle.bottomthird.inset.fill"),
                                style: model.hasBottomBarArea ? activeStyle : inactiveStyle )
    }
}

// MARK: - Actions
private extension LayoutGridManagerViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Grid Control
    @IBAction func gridEnablingButtonTouchedUpInside(_ sender: Any) {
        model.toggleVisibleState()
        updateGridVisibility()
    }
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let mode = TopBarMode(rawValue: sender.selectedSegmentIndex) else { return }
        model.setTopBarMode(mode)
    }
    @IBAction func topAreaButtonTouchedUpInside(_ sender: Any) {
        model.toggle(.topBar)
        updateControls()
    }
    @IBAction func leftPanelButtonTouchedUpInside(_ sender: Any) {
        model.toggle(.leftPanel)
        updateControls()
    }
    @IBAction func centerGuidesButtonTouchedUpInside(_ sender: Any) {
        model.toggleCenterGuides()
        updateControls()
    }
    @IBAction func rightPanelButtonTouchedUpInside(_ sender: Any) {
        model.toggle(.rightPanel)
        updateControls()
    }
    @IBAction func bottomAreaButtonTouchedUpInside(_ sender: Any) {
        model.toggle(.bottomBar)
        updateControls()
    }
}
