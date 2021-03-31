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
    @IBOutlet private weak var arcadeHelpLabel: UILabel! {
        didSet {
            arcadeHelpLabel.makeUp(and: .orangePeel)
            arcadeHelpLabel.adjustsFontSizeToFitWidth = true
            arcadeHelpLabel.isHidden = true
        }
    }
    @IBOutlet private weak var remoteJogsView: UIView!
    @IBOutlet private weak var virtualJogsView: UIView!
    @IBOutlet private weak var inverseJoystickButton: UIButton!
    @IBOutlet private weak var inverseJoystickLabel: UILabel! {
        didSet {
            inverseJoystickLabel.makeUp()
        }
    }
    @IBOutlet private weak var specialModeButton: UIButton!
    @IBOutlet private weak var specialModeLabel: UILabel! {
        didSet {
            specialModeLabel.makeUp()
        }
    }
    @IBOutlet private weak var inverseTiltButton: UIButton!
    @IBOutlet private weak var inverseTiltLabel: UILabel! {
        didSet {
            inverseTiltLabel.makeUp()
        }
    }
    @IBOutlet private weak var inverseTiltView: UIView!
    @IBOutlet private weak var evTriggerView: UIView!
    @IBOutlet private weak var evTriggerButton: UIButton!
    @IBOutlet private weak var evTriggerLabel: UILabel! {
        didSet {
            evTriggerLabel.makeUp()
        }
    }
    @IBOutlet private weak var joystickImage: UIImageView!
    @IBOutlet private weak var controllerCameraLabel: UILabel! {
        didSet {
            controllerCameraLabel.makeUp()
        }
    }
    @IBOutlet private weak var controllerSpeedModeLabel: UILabel! {
        didSet {
            controllerSpeedModeLabel.makeUp()
        }
    }
    @IBOutlet private weak var controllerZoomLabel: UILabel! {
        didSet {
            controllerZoomLabel.makeUp()
        }
    }
    @IBOutlet private weak var controllerRecordLabel: UILabel! {
        didSet {
            controllerRecordLabel.makeUp()
        }
    }
    @IBOutlet private weak var controllerLeftJoystickLabel: UILabel! {
        didSet {
            controllerLeftJoystickLabel.makeUp()
        }
    }
    @IBOutlet private weak var controllerRightJoystickLabel: UILabel! {
        didSet {
            controllerRightJoystickLabel.makeUp()
        }
    }
    @IBOutlet private weak var hudCameraLabel: UILabel! {
        didSet {
            hudCameraLabel.makeUp()
        }
    }
    @IBOutlet private weak var hudZoom: UILabel! {
        didSet {
            hudZoom.makeUp()
        }
    }
    @IBOutlet private weak var hudLeftJoystick: UILabel! {
        didSet {
            hudLeftJoystick.makeUp()
        }
    }
    @IBOutlet private weak var hudRightJoystick: UILabel! {
        didSet {
            hudRightJoystick.makeUp()
        }
    }
    @IBOutlet private weak var pilotingModeView: PilotingModeView!

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

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapPilotingView))
        pilotingModeView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Internal Funcs
    func configureCell(viewModel: ControlsViewModel) {
        self.viewModel = viewModel
        self.styleDidChanged(state: viewModel.state.value)
    }

}

// MARK: - Actions
private extension SettingsControlModeCell {
    /// Inverse button touched.
    @IBAction func inverseButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.inverseJoys,
                             newValue: String(!jogsInversed),
                             logType: LogEvent.LogType.button)

        jogsInversed = !jogsInversed
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// Tilt button touched.
    @IBAction func inverseTiltButtonTouchedUpInside(_ sender: AnyObject) {
        let tiltReversedSetting = Defaults.arcadeTiltReversedSetting
        Defaults.arcadeTiltReversedSetting = !tiltReversedSetting
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// Special button touched.
    @IBAction func specialModeButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.special,
                             newValue: String(!isSpecialMode),
                             logType: LogEvent.LogType.button)

        isSpecialMode.toggle()
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// EV trigger button touched.
    @IBAction func evTriggerButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.controls,
                             itemName: LogEvent.LogKeyControlsSettings.evTrigger,
                             newValue: String(!Defaults.evTriggerSetting),
                             logType: LogEvent.LogType.button)

        Defaults.evTriggerSetting.toggle()
        deduceCurrentMode()
        updateJogsDisplay()
    }

    /// Display why arcade mode is not available on piloting style view tapped.
    @objc func tapPilotingView(sender: Any) {
        guard let viewModel = viewModel,
              viewModel.state.value.isArcadeModeAvailable == false else {
            return
        }

        arcadeHelpLabel.text = viewModel.arcadeUnavailabilityHelp
        arcadeHelpLabel.isHidden = (arcadeHelpLabel.text?.isEmpty ?? true)
    }
}

// MARK: - Private Funcs
private extension SettingsControlModeCell {
    /// Inits the view.
    func initView() {
        inverseJoystickLabel.text = L10n.settingsControlsOptionInverseJoys
        inverseJoystickButton.setImage(Asset.Settings.Controls.reverseJoy.image.withRenderingMode(.alwaysTemplate), for: .normal)
        applyCorneredStyle(inverseJoystickButton)

        inverseTiltLabel.text = L10n.settingsControlsOptionReverseTilt
        inverseTiltButton.setImage(Asset.Settings.Controls.inverseTilt.image.withRenderingMode(.alwaysTemplate), for: .normal)
        applyCorneredStyle(inverseTiltButton)

        specialModeLabel.text = L10n.settingsControlsOptionSpecial
        specialModeButton.setImage(Asset.Settings.Controls.special.image.withRenderingMode(.alwaysTemplate), for: .normal)
        applyCorneredStyle(specialModeButton)

        evTriggerLabel.text = L10n.settingsControlsOptionEvTrigger
        evTriggerButton.setImage(Asset.Settings.Controls.evTrigger.image.withRenderingMode(.alwaysTemplate), for: .normal)
        applyCorneredStyle(evTriggerButton)

        updateEVTriggerButtonColor()
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
        evTriggerView.isHidden = showVirtualJogs
        currentMode = viewModel.currentControlMode
        currentPilotingStyle = currentMode.pilotingStyle
        inverseTiltView.isHidden = currentPilotingStyle == .classical
        updateJogsDisplay()
        pilotingModeView.setup(with: viewModel)
        arcadeHelpLabel.text = viewModel.arcadeUnavailabilityHelp
        // FIXME: Temporary disable arcade mode.
        pilotingModeView.isHidden = true
    }

    /// Update jogs display regarding current mode.
    func updateJogsDisplay() {
        updateEVTriggerButtonColor()
        let tiltReversedSetting = Defaults.arcadeTiltReversedSetting
        let tiltColor = tiltReversedSetting ? ColorName.greenSpring.color : ColorName.white.color
        setButtonAndLabelColor(button: inverseTiltButton, label: inverseTiltLabel, color: tiltColor)

        let joystickColor = currentMode.jogsInversed ? ColorName.greenSpring.color : ColorName.white.color
        setButtonAndLabelColor(button: inverseJoystickButton, label: inverseJoystickLabel, color: joystickColor)

        let specialColor = currentMode.isSpecialMode ? ColorName.greenSpring.color : ColorName.white.color
        setButtonAndLabelColor(button: specialModeButton, label: specialModeLabel, color: specialColor)

        joystickImage.image = currentMode.joystickImage
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

    /// Apply cornered style on a button.
    ///
    /// - Parameters:
    ///     - button: button to apply style on
    func applyCorneredStyle(_ button: UIButton) {
        button.roundCorneredWith(backgroundColor: .clear, borderColor: ColorName.white.color, borderWidth: 0.5)
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

    /// Update EV trigger button color regarding setting.
    func updateEVTriggerButtonColor() {
        let evTriggerSetting = Defaults.evTriggerSetting
        let color = evTriggerSetting ? ColorName.greenSpring.color : ColorName.white.color
        setButtonAndLabelColor(button: evTriggerButton, label: evTriggerLabel, color: color)
    }

    /// Update joystick labels regarding the current mode.
    func updateJoystickLabels() {
        let evTriggerSetting = Defaults.evTriggerSetting
        controllerZoomLabel.text = !evTriggerSetting ?
            L10n.settingsControlsMappingZoom :
            L10n.settingsControlsMappingEvShutter

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
}
