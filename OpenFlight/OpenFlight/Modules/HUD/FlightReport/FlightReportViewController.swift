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
import Combine

/// Displays a flight report inside HUD.
final class FlightReportViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var flightNameTitleLabel: UILabel!
    @IBOutlet private weak var flightNameContainerView: UIView!
    @IBOutlet private weak var flightNameLabel: UILabel!
    @IBOutlet private weak var flightNameLabelStackView: UIStackView!
    @IBOutlet private weak var flightNameTextfield: UITextField!
    // MARK: Flight Infos
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var flightTimeInfoView: FlightReportInfoView!
    @IBOutlet private weak var totalDistanceInfoView: FlightReportInfoView!
    @IBOutlet private weak var batteryUsedInfoView: FlightReportInfoView!
    @IBOutlet private weak var nbPhotosInfoView: FlightReportInfoView!
    @IBOutlet private weak var nbVideosInfoView: FlightReportInfoView!
    @IBOutlet private weak var memoryUsedInfoView: FlightReportInfoView!

    // MARK: Flight Diagnostics
    @IBOutlet private weak var diagnosticContainerView: UIView!
    @IBOutlet private weak var diagnosticLabel: UILabel!
    @IBOutlet private weak var storageSpaceValueLabel: UILabel!
    @IBOutlet private weak var batteryLevelImageView: UIImageView!
    @IBOutlet private weak var batteryLevelLabel: UILabel!
    // MARK: Constraints
    @IBOutlet private weak var scrollViewBottomConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private var viewModel: FlightDetailsViewModel!
    private var cancellables = Set<AnyCancellable>()
    private let droneInfosViewModel = DroneInfosViewModel()

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    /// Instantiates FlightReport ViewController.
    ///
    /// - Parameters:
    ///     - viewModel: view model
    static func instantiate(viewModel: FlightDetailsViewModel) -> FlightReportViewController {
        let viewController = StoryboardScene.FlightReport.flightReportViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        addTapGestures()
        setupKeyboardNotificationObservers()
        setupFlightInfoModels()
        setupFlightViewModel()
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
    /// Sets up view
    func setupView() {
        mainView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)
        flightNameContainerView.layer.cornerRadius = Style.largeCornerRadius
        titleLabel.text = L10n.flightReportTitle
        flightNameTitleLabel.text = L10n.flightInfoName
        flightNameTextfield.isHidden = true
        diagnosticContainerView.layer.cornerRadius = Style.largeCornerRadius
        diagnosticLabel.text = L10n.diagnosticsFlightReportEverythingOk
    }

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
        nbPhotosInfoView.model = FlightReportInfoModel(image: Asset.Dashboard.icPhotoMini.image,
                                                       title: L10n.flightInfoPhotos.uppercased(),
                                                       value: Style.dash)
        nbVideosInfoView.model = FlightReportInfoModel(image: Asset.Dashboard.icVideoMini.image,
                                                       title: L10n.flightInfoVideos.uppercased(),
                                                       value: Style.dash)
        memoryUsedInfoView.model = FlightReportInfoModel(image: nil,
                                                         title: L10n.flightInfoMemoryUsed.uppercased(),
                                                         value: Style.dash)
    }

    /// Sets up flight view model for information display.
    func setupFlightViewModel() {
        flightTimeInfoView.model?.value = viewModel.flight.formattedDuration
        totalDistanceInfoView.model?.value = viewModel.flight.formattedDistance
        batteryUsedInfoView.model?.value = viewModel.flight.batteryConsumptionPercents
        nbPhotosInfoView.model?.value = viewModel.flight.formattedPhotoCount
        nbVideosInfoView.model?.value = viewModel.flight.formattedVideoCount
        dateLabel.text = viewModel.flight.formattedDate
        locationLabel.text = viewModel.flight.formattedPosition
        viewModel.$name
            .sink { [unowned self] in
                flightNameLabel.text = $0
                flightNameTextfield.text = $0
            }
            .store(in: &cancellables)
        viewModel.$sdcardAvailableSpace
            .sink { [unowned self] availableSpace in
                storageSpaceValueLabel.text = availableSpace
            }
            .store(in: &cancellables)
        viewModel.$memoryUsed
            .sink { [unowned self] memoryUsed in
                memoryUsedInfoView.model?.value = memoryUsed
            }
            .store(in: &cancellables)
        droneInfosViewModel.$batteryLevel
            .sink { [unowned self] batteryLevel in
                if let batteryValue = batteryLevel.currentValue {
                    batteryLevelLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue)
                } else {
                    batteryLevelLabel.text = Style.dash
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITextField Delegate
extension FlightReportViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let newTitle = textField.text, !newTitle.isEmpty {
            viewModel.set(name: newTitle)
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
