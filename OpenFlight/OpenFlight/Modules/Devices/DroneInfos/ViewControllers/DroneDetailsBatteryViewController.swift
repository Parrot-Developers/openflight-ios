//    Copyright (C) 2022 Parrot Drones SAS
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
import GroundSdk

class DroneDetailsBatteryViewController: UIViewController {

    // MARK: - Outlet
    @IBOutlet private weak var popupLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var popupTrailingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var batteryView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var voltage1Label: UILabel!
    @IBOutlet private weak var voltage2Label: UILabel!
    @IBOutlet private weak var voltage3Label: UILabel!
    @IBOutlet private weak var voltage1ProgressView: UIProgressView!
    @IBOutlet private weak var voltage2ProgressView: UIProgressView!
    @IBOutlet private weak var voltage3ProgressView: UIProgressView!
    @IBOutlet private weak var voltage1View: UIView!
    @IBOutlet private weak var voltage2View: UIView!
    @IBOutlet private weak var voltage3View: UIView!
    @IBOutlet private weak var totalVoltageLabel: UILabel!
    @IBOutlet private weak var totalVoltageValueLabel: UILabel!
    @IBOutlet private weak var capacityLabel: UILabel!
    @IBOutlet private weak var capacityValueLabel: UILabel!
    @IBOutlet private weak var healthLabel: UILabel!
    @IBOutlet private weak var healthValueLabel: UILabel!
    @IBOutlet private weak var cyclesLabel: UILabel!
    @IBOutlet private weak var cyclesValueLabel: UILabel!
    @IBOutlet private weak var serialNumberLabel: UILabel!
    @IBOutlet private weak var serialNumberValueLabel: UILabel!
    @IBOutlet private weak var softwareVersionLabel: UILabel!
    @IBOutlet private weak var softwareVersionValueLabel: UILabel!
    @IBOutlet private weak var hardwareVersionLabel: UILabel!
    @IBOutlet private weak var harwareVersionValueLabel: UILabel!
    @IBOutlet private weak var configurationDateLabel: UILabel!
    @IBOutlet private weak var configurationDateValueLabel: UILabel!
    @IBOutlet private weak var batteryPercentageValueLabel: UILabel!
    @IBOutlet private weak var batteryImage: UIImageView!
    @IBOutlet private weak var temperatureValueLabel: UILabel!
    @IBOutlet private weak var cellsVoltageLabel: UILabel!

    // MARK: - Privates properties

    private var viewModel: DroneDetailsBatteryViewModel!
    private var cancellables = Set<AnyCancellable>()

    static func instantiate(viewModel: DroneDetailsBatteryViewModel) -> DroneDetailsBatteryViewController {
        let viewController = StoryboardScene.DroneDetailsBatteryViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        addTouchGesture()
        setupUI()
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addColorTransition()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.backgroundColor = .clear
    }

    // MARK: - Actions

    @IBAction func closeButtonTouchUpInside(_ sender: Any) {
        viewModel.dismissView()
    }

}

extension DroneDetailsBatteryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
         if touch.view?.isDescendant(of: batteryView) == true {
            return false
         }
         return true
    }
}

private extension DroneDetailsBatteryViewController {

    func setupUI() {
        popupLeadingConstraint.constant = Layout.popupHMargin(isRegularSizeClass)
        popupTrailingConstraint.constant = popupLeadingConstraint.constant

        titleLabel.text = L10n.batteryInformation
        titleLabel.makeUp(with: .title, color: .defaultTextColor)
        cellsVoltageLabel.text = L10n.batteryCellsVoltage
        cellsVoltageLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        batteryView.customCornered(corners: [.topLeft, .topRight], radius: Style.largeCornerRadius)

        setupVoltageLabels()
        setupLeftInfoLabels()
        setupRightInfoLabels()
        setupInfosLabels()
        setupProgressView()
    }

    func setupProgressView() {
        voltage1ProgressView.tintColor = ColorName.highlightColor.color
        voltage1ProgressView.setProgress(0.0, animated: false)
        voltage1ProgressView.layer.cornerRadius = Style.mediumCornerRadius
        voltage1ProgressView.layer.masksToBounds = true
        voltage1ProgressView.transform = CGAffineTransform(rotationAngle: .pi / -2)

        voltage2ProgressView.tintColor = ColorName.highlightColor.color
        voltage2ProgressView.setProgress(0.0, animated: false)
        voltage2ProgressView.layer.cornerRadius = Style.mediumCornerRadius
        voltage2ProgressView.layer.masksToBounds = true
        voltage2ProgressView.transform = CGAffineTransform(rotationAngle: .pi / -2)

        voltage3ProgressView.tintColor = ColorName.highlightColor.color
        voltage3ProgressView.setProgress(0.0, animated: false)
        voltage3ProgressView.layer.cornerRadius = Style.mediumCornerRadius
        voltage3ProgressView.layer.masksToBounds = true
        voltage3ProgressView.transform = CGAffineTransform(rotationAngle: .pi / -2)

        voltage1View.cornerRadiusedWith(backgroundColor: .white,
                                        borderColor: .black,
                                        radius: Style.mediumCornerRadius,
                                        borderWidth: 1.0)
        voltage2View.cornerRadiusedWith(backgroundColor: .white,
                                        borderColor: .black,
                                        radius: Style.mediumCornerRadius,
                                        borderWidth: 1.0)
        voltage3View.cornerRadiusedWith(backgroundColor: .white,
                                        borderColor: .black,
                                        radius: Style.mediumCornerRadius,
                                        borderWidth: 1.0)
    }

    func setupVoltageLabels() {
        voltage1Label.makeUp(with: .medium, color: .defaultTextColor)
        voltage2Label.makeUp(with: .medium, color: .defaultTextColor)
        voltage3Label.makeUp(with: .medium, color: .defaultTextColor)
    }

    func setupInfosLabels() {
        temperatureValueLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        batteryPercentageValueLabel.makeUp(with: .subtitle, color: .defaultTextColor)
    }

    func setupLeftInfoLabels() {
        serialNumberLabel.text = L10n.batterySerialNumber
        serialNumberLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        serialNumberValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        softwareVersionLabel.text = L10n.batterySoftwareVersion
        softwareVersionLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        softwareVersionValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        hardwareVersionLabel.text = L10n.batteryHardwareRevision
        hardwareVersionLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        harwareVersionValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        configurationDateLabel.text = L10n.batteryConfigurationDate
        configurationDateLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        configurationDateValueLabel.makeUp(with: .medium, color: .defaultTextColor)
    }

    func setupRightInfoLabels() {
        totalVoltageLabel.text = L10n.batteryVoltage
        totalVoltageLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        totalVoltageValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        capacityLabel.text = L10n.batteryTotalCapacity
        capacityLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        capacityValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        healthLabel.text = L10n.batteryHealth
        healthLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        healthValueLabel.makeUp(with: .medium, color: .defaultTextColor)

        cyclesLabel.text = L10n.batteryCycles
        cyclesLabel.makeUp(with: .subtitle, color: .defaultTextColor)
        cyclesValueLabel.makeUp(with: .medium, color: .defaultTextColor)
    }

    func bindViewModel() {
        bindRightInfos()
        bindLeftInfos()
        bindInfos()
        bindProgress()
        bindVoltage()
    }

    func bindRightInfos() {
        viewModel.$totalVoltage.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.totalVoltageValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$capacity.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.capacityValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$health.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.healthValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$cycles.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.cyclesValueLabel.text = $0
            }
            .store(in: &cancellables)
    }

    func bindLeftInfos() {
        viewModel.$serialNumber.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.serialNumberValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$firmwareVersion.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.softwareVersionValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$hardwareRevision.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.harwareVersionValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$configurationDate.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.configurationDateValueLabel.text = $0
            }
            .store(in: &cancellables)
    }

    func bindInfos() {
        viewModel.$temperature.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.temperatureValueLabel.text = $0
            }
            .store(in: &cancellables)

        viewModel.$batteryLevel
            .sink { [unowned self] batteryValue in
                batteryPercentageValueLabel.attributedText = NSMutableAttributedString(withBatteryLevel: batteryValue.currentValue)
                batteryImage.image = batteryValue.batteryImage
            }
            .store(in: &cancellables)
    }

    func bindProgress() {
        viewModel.$progress1.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage1ProgressView.setProgress($0, animated: true)
            }
            .store(in: &cancellables)

        viewModel.$progress2.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage2ProgressView.setProgress($0, animated: true)
            }
            .store(in: &cancellables)

        viewModel.$progress3.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage3ProgressView.setProgress($0, animated: true)
            }
            .store(in: &cancellables)
    }

    func bindVoltage() {
        viewModel.$voltage1.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage1Label.text = $0
            }
            .store(in: &cancellables)

        viewModel.$voltage2.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage2Label.text = $0
            }
            .store(in: &cancellables)

        viewModel.$voltage3.removeDuplicates()
            .sink { [weak self] in
                guard let self = self else { return }
                self.voltage3Label.text = $0
            }
            .store(in: &cancellables)
    }

    @objc func closeBatteryViewFromTouch() {
        viewModel.dismissView()
    }

    /// Adds a tap gesture recognizer to dismiss the modal
    func addTouchGesture() {
        let touchGesture = UITapGestureRecognizer(target: self, action: #selector(closeBatteryViewFromTouch))
        touchGesture.delegate = self
        view.addGestureRecognizer(touchGesture)
    }

    /// Adds a background to the view at the back
    func addColorTransition() {
        UIView.animate(withDuration: Style.shortAnimationDuration, delay: 0, options: .allowUserInteraction) {
            self.view.backgroundColor = ColorName.greyDark60.color
        }
    }
}
