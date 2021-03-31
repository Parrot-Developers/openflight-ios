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

/// Displays a flight report inside HUD.
final class FlightReportViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var mainView: UIView! {
        didSet {
            mainView.addBlurEffect(cornerRadius: Style.mediumCornerRadius)
        }
    }
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .huge)
            titleLabel.text = L10n.flightReportTitle
        }
    }
    // MARK: Flight Name
    @IBOutlet private weak var flightNameTitleLabel: UILabel! {
        didSet {
            flightNameTitleLabel.makeUp()
            flightNameTitleLabel.text = L10n.flightInfoName
        }
    }
    @IBOutlet private weak var flightNameContainerView: UIView! {
        didSet {
            flightNameContainerView.applyCornerRadius()
        }
    }
    @IBOutlet private weak var flightNameLabel: UILabel! {
        didSet {
            flightNameLabel.makeUp(with: .large )
        }
    }
    @IBOutlet private weak var flightNameLabelStackView: UIStackView!
    @IBOutlet private weak var flightNameTextfield: UITextField! {
        didSet {
            flightNameTextfield.makeUp(style: .large)
            flightNameTextfield.tintColor = .white
            flightNameTextfield.backgroundColor = .clear
            flightNameTextfield.isHidden = true
        }
    }
    // MARK: Flight Infos
    @IBOutlet private weak var dateLabel: UILabel! {
        didSet {
            dateLabel.makeUp(with: .large, and: .white50)
        }
    }
    @IBOutlet private weak var locationLabel: UILabel! {
        didSet {
            locationLabel.makeUp(with: .large, and: .white50)
        }
    }
    @IBOutlet private weak var flightTimeInfoView: FlightReportInfoView!
    @IBOutlet private weak var totalDistanceInfoView: FlightReportInfoView!
    @IBOutlet private weak var batteryUsedInfoView: FlightReportInfoView!
    // MARK: Flight Diagnostics
    @IBOutlet private weak var diagnosticLabel: UILabel! {
        didSet {
            diagnosticLabel.makeUp(with: .large, and: .greenSpring)
            diagnosticLabel.text = L10n.diagnosticsFlightReportEverythingOk
        }
    }
    @IBOutlet private weak var storageSpaceCircleView: CircleProgressView! {
        didSet {
            storageSpaceCircleView.strokeColor = ColorName.greenSpring.color
        }
    }
    @IBOutlet private weak var storageSpaceValueLabel: UILabel! {
        didSet {
            storageSpaceValueLabel.makeUp(with: .large)
        }
    }
    @IBOutlet private weak var storageSpaceUnitLabel: UILabel! {
        didSet {
            storageSpaceUnitLabel.makeUp(and: .white50)
        }
    }
    @IBOutlet private weak var batteryLevelImageView: UIImageView!
    @IBOutlet private weak var batteryLevelLabel: UILabel! {
        didSet {
            batteryLevelLabel.makeUp(with: .large)
        }
    }
    // MARK: Constraints
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var flightViewModel: FlightDataViewModel?

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    /// Instantiates FlightReport ViewController.
    ///
    /// - Parameters:
    ///     - flightState: flight state
    static func instantiate(flightState: FlightDataState) -> FlightReportViewController {
        let viewController = StoryboardScene.FlightReport.flightReportViewController.instantiate()
        viewController.flightViewModel = FlightDataViewModel(state: flightState)
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        addTapGestures()
        setupKeyboardNotificationObservers()
        setupFlightInfoModels()
        setupFlightViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // TODO: remove this and replace with real values
        storageSpaceCircleView.setProgress(0.25)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension FlightReportViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismissFlightReport()
    }

    @IBAction func editButtonTouchedUpInside(_ sender: Any) {
        editTitle()
    }

    /// Enters edition mode for flight title.
    @objc func editTitle() {
        flightNameTextfield.becomeFirstResponder()
        flightNameLabelStackView.isHidden.toggle()
        flightNameTextfield.isHidden.toggle()
    }

    /// Dismisses the view.
    @objc func dismissFlightReport() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private Funcs
private extension FlightReportViewController {
    /// Adds tap gestures to the views.
    func addTapGestures() {
        let dismissTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissFlightReport))
        backgroundView.addGestureRecognizer(dismissTapGesture)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(editTitle))
        flightNameLabel.addGestureRecognizer(gesture)
        flightNameLabel.isUserInteractionEnabled = true
        flightNameTextfield.delegate = self
    }

    /// Sets up notification observers for keyboard.
    func setupKeyboardNotificationObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(sender:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(sender:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    /// Sets up models for flight informations.
    func setupFlightInfoModels() {
        flightTimeInfoView.model = FlightReportInfoModel(image: Asset.Common.Icons.icFlightPlanTimer.image,
                                                         title: L10n.flightInfoFlightTime.uppercased(),
                                                         value: Style.dash)
        totalDistanceInfoView.model = FlightReportInfoModel(image: Asset.MyFlights.distance.image,
                                                            title: L10n.flightInfoTotalDistance.uppercased(),
                                                            value: Style.dash)
        batteryUsedInfoView.model = FlightReportInfoModel(image: Asset.Common.Icons.icBattery.image,
                                                          title: L10n.flightInfoBatteryUsed.uppercased(),
                                                          value: Style.dash)
    }

    /// Sets up flight view model for information display.
    func setupFlightViewModel() {
        flightViewModel?.loadGutmaContent()
        flightViewModel?.state.valueChanged = { [weak self] state in
            self?.flightTimeInfoView.model?.value = state.formattedDuration
            self?.totalDistanceInfoView.model?.value = state.formattedDistance
            self?.batteryUsedInfoView.model?.value = state.batteryConsumption
            self?.dateLabel.text = state.formattedDate
            self?.locationLabel.text = state.formattedPosition
            self?.flightNameLabel.text = state.title
            self?.flightNameTextfield.text = state.title
        }
    }
}

// MARK: - UITextField Delegate
extension FlightReportViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newTitle = textField.text, !newTitle.isEmpty {
            flightViewModel?.updateTitle(newTitle)
        }
        flightNameLabelStackView.isHidden.toggle()
        flightNameTextfield.isHidden.toggle()
        return true
    }
}

// MARK: - Keyboard Helpers
private extension FlightReportViewController {
    /// Manages view display when keyboard is displayed.
    @objc func keyboardWillShow(sender: NSNotification) {
        // Only active in portrait.
        if UIApplication.isLandscape == false,
            let userInfo = sender.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Move view upward.
            scrollViewBottomConstraint.constant = keyboardFrame.size.height
        }
    }

    /// Manages view display after keyboard was displayed.
    @objc func keyboardWillHide(sender: NSNotification) {
        // Move view to original position.
        scrollViewBottomConstraint.constant = 0
    }
}
