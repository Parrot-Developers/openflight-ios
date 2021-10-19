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

import Reusable
import SwiftyUserDefaults

/// Settings control mode cell manage all the control settings.
/// All the control settings are handled here because there are all linked.
final class SettingsControlModeCell: UITableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var zoomExpoSegmentedControl: UISegmentedControl! {
        didSet {
            setupZoomExpoSegmentedControl()
        }
    }
    @IBOutlet private weak var remoteJogsView: UIStackView!
    @IBOutlet private weak var virtualJogsView: UIStackView!
    @IBOutlet private weak var inverseJoystickView: UIView! {
        didSet {
            inverseJoystickView.cornerRadiusedWith(backgroundColor: ColorName.whiteAlbescent.color, radius: Style.largeCornerRadius)
        }
    }
    @IBOutlet private weak var inverseJoystickButton: UIButton!
    @IBOutlet private weak var inverseJoystickLabel: UILabel!
    @IBOutlet weak var joystickModeView: UIView! {
        didSet {
            joystickModeView.cornerRadiusedWith(backgroundColor: ColorName.white.color, radius: Style.largeCornerRadius)
        }
    }
    @IBOutlet private weak var joystickModeSegmentedControl: UISegmentedControl! {
        didSet {
            setupJoystickModeSegmentedControl()
        }
    }
    @IBOutlet private weak var joystickModeLabel: UILabel! {
        didSet {
            joystickModeLabel.text = L10n.settingsControlsOptionJoystickMode
        }
    }
    @IBOutlet private weak var joystickImage: UIImageView!
    @IBOutlet private weak var controllerCameraLabel: UILabel!
    @IBOutlet private weak var controllerSpeedModeLabel: UILabel!
    @IBOutlet private weak var controllerRecordLabel: UILabel!
    @IBOutlet private weak var controllerLeftJoystickLabel: UILabel!
    @IBOutlet private weak var controllerRightJoystickLabel: UILabel!
    @IBOutlet private weak var hudCameraLabel: UILabel!
    @IBOutlet private weak var hudZoom: UILabel!
    @IBOutlet private weak var hudLeftJoystick: UILabel!
    @IBOutlet private weak var hudRightJoystick: UILabel!

    // MARK: - Private Properties
    private var currentMode: ControlsSettingsMode = ControlsSettingsMode.defaultMode
    private var jogsInversed = false
    private var isSpecialMode = false
    private var currentPilotingStyle: PilotingStyle = ControlsSettingsMode.defaultPilotingMode
    private var viewModel: ControlsViewModel?

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    // MARK: - Internal Funcs
    func configureCell(viewModel: ControlsViewModel) {
        self.viewModel = viewModel
        self.styleDidChanged(state: viewModel.state.value)
    }
}

// MARK: - Actions
private extension SettingsControlModeCell {
    /// zoom exposure segment changed.
    @IBAction func zoomExpoSegmentDidChange(_ sender: UISegmentedControl) {
        let evTriggerSettings = sender.selectedSegmentIndex == 0 ? false : true
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.evTrigger,
                             newValue: String(evTriggerSettings),
                             logType: LogEvent.LogType.button)

        Defaults.evTriggerSetting = evTriggerSettings
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// joystick mode segment changed.
    @IBAction func joystickModeSegmentDidChange(_ sender: UISegmentedControl) {
        let isSpecialMode = sender.selectedSegmentIndex == 0 ? false : true
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.special,
                             newValue: String(isSpecialMode),
                             logType: LogEvent.LogType.button)

        self.isSpecialMode = isSpecialMode
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// Inverse button touched.
    @IBAction func inverseButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.inverseJoys,
                             newValue: String(!jogsInversed),
                             logType: LogEvent.LogType.button)

        jogsInversed.toggle()
        deduceCurrentMode()
        updateJogsDisplay()
    }
}

// MARK: - Private Funcs
private extension SettingsControlModeCell {
    /// Inits the view.
    func initView() {
        inverseJoystickLabel.text = L10n.settingsControlsOptionInverseJoys
        inverseJoystickButton.setImage(Asset.Settings.Controls.reverseJoy.image.withRenderingMode(.alwaysTemplate), for: .normal)
    }

    /// Control mode did change.
    ///
    /// - Parameters:
    ///     - state: current control state
    func styleDidChanged(state: ControlsState) {
        guard let viewModel = viewModel else { return }

        let showVirtualJogs = viewModel.state.value.isVirtualJogsAvailable
        remoteJogsView.isHidden = showVirtualJogs
        virtualJogsView.isHidden = !showVirtualJogs
        currentMode = viewModel.currentControlMode
        currentPilotingStyle = currentMode.pilotingStyle

        updateJogsDisplay()
    }

    /// Update jogs display regarding current mode.
    func updateJogsDisplay() {
        let backgroundColor = currentMode.jogsInversed ? ColorName.highlightColor.color : ColorName.whiteAlbescent.color
        let textColor = currentMode.jogsInversed ? ColorName.white.color : ColorName.defaultTextColor.color
        setButtonAndLabelColor(button: inverseJoystickButton, label: inverseJoystickLabel, color: textColor)
        inverseJoystickView.cornerRadiusedWith(backgroundColor: backgroundColor, radius: Style.largeCornerRadius)
        joystickImage.image = currentMode.getJoystickImage(isRegularSizeClass: isRegularSizeClass)
        jogsInversed = currentMode.jogsInversed
        isSpecialMode = currentMode.isSpecialMode
        updateJoystickLabels()
    }

    /// Deduce current mode regarding states.
    func deduceCurrentMode() {
        if !isSpecialMode && jogsInversed {
            currentMode = .mode3(currentPilotingStyle)
        } else if !isSpecialMode && !jogsInversed {
            currentMode = .mode2(currentPilotingStyle)
        } else if isSpecialMode && jogsInversed {
            currentMode = .mode4(currentPilotingStyle)
        } else if isSpecialMode && !jogsInversed {
            currentMode = .mode1(currentPilotingStyle)
        }

        viewModel?.updateRemoteMapping(withMode: currentMode)
    }

    /// Apply color on a button and a label.
    ///
    /// - Parameters:
    ///     - button: button to apply color on
    ///     - label: label to apply color on
    ///     - color: color to apply
    func setButtonAndLabelColor(button: UIButton, label: UILabel, color: UIColor) {
        button.setTitleColor(color, for: .normal)
        button.tintColor = color
        button.layer.borderColor = color.cgColor
        label.textColor = color
    }

    /// Update joystick labels regarding the current mode.
    func updateJoystickLabels() {
        controllerCameraLabel.text = currentMode.controllerCameraText
        controllerLeftJoystickLabel.text = currentMode.controllerLeftJoystickText
        hudLeftJoystick.text = currentMode.hudLeftJoystickText
        controllerRightJoystickLabel.text = currentMode.controllerRightJoystickText
        hudRightJoystick.text = currentMode.hudRightJoystickText
        hudZoom.text = L10n.settingsControlsMappingZoom
        controllerSpeedModeLabel.text = L10n.settingsControlsMappingReset
        controllerRecordLabel.text = L10n.settingsControlsMappingRecord
        hudCameraLabel.text = L10n.settingsControlsMappingCamera
    }

    /// Setup zoom exposure segmented control.
    func setupZoomExpoSegmentedControl() {
        let selectedSegmentIndex = !Defaults.evTriggerSetting ? 0 : 1
        zoomExpoSegmentedControl.customMakeup(normalBackgroundColor: .whiteAlbescent)
        zoomExpoSegmentedControl.removeAllSegments()
        zoomExpoSegmentedControl.insertSegment(withTitle: L10n.settingsControlsMappingZoom,
                                               at: zoomExpoSegmentedControl.numberOfSegments,
                                               animated: false)
        zoomExpoSegmentedControl.insertSegment(withTitle: L10n.settingsControlsMappingExposure,
                                               at: zoomExpoSegmentedControl.numberOfSegments,
                                               animated: false)
        zoomExpoSegmentedControl.selectedSegmentIndex = selectedSegmentIndex
    }
    /// Setup joystick mode segmented control.
    func setupJoystickModeSegmentedControl() {
        let selectedSegmentIndex = currentMode.isSpecialMode ? 0 : 1
        joystickModeSegmentedControl.customMakeup()
        joystickModeSegmentedControl.removeAllSegments()
        joystickModeSegmentedControl.insertSegment(withTitle: L10n.settingsControlsOptionJoystickModeNumber(1),
                                                   at: joystickModeSegmentedControl.numberOfSegments,
                                                   animated: false)
        joystickModeSegmentedControl.insertSegment(withTitle: L10n.settingsControlsOptionJoystickModeNumber(2),
                                                   at: joystickModeSegmentedControl.numberOfSegments,
                                                   animated: false)
        joystickModeSegmentedControl.selectedSegmentIndex = selectedSegmentIndex
    }
}
