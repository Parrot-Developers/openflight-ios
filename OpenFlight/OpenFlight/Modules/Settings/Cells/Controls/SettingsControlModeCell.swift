//    Copyright (C) 2020 Parrot Drones SAS
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
final class SettingsControlModeCell: MainTableViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var zoomExpoSegmentedControl: SettingsSegmentedControl!
    @IBOutlet private weak var remoteJogsView: UIStackView!
    @IBOutlet private weak var virtualJogsView: UIStackView!
    @IBOutlet private weak var inverseJoystickButton: ActionButton!
    @IBOutlet private weak var joystickModeStackView: UIStackView!
    @IBOutlet private weak var joystickModeSegmentedControl: SettingsSegmentedControl!
    @IBOutlet private weak var joystickModeLabel: UILabel!
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
    private var jogsInversed = ControlsSettingsMode.defaultMode.jogsInversed
    private var isSpecialMode = ControlsSettingsMode.defaultMode.isSpecialMode
    private var viewModel: ControlsViewModel?

    // MARK: - Init
    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    // MARK: - Internal Funcs
    func configureCell(viewModel: ControlsViewModel) {
        self.viewModel = viewModel
        styleDidChanged(state: viewModel.state.value)
    }
}

// MARK: - Actions
private extension SettingsControlModeCell {
    /// Inverse button touched.
    @IBAction func inverseButtonTouchedUpInside(_ sender: AnyObject) {
        LogEvent.log(.button(item: LogEvent.LogKeyControlsSettings.inverseJoys, value: String(!jogsInversed)))

        jogsInversed.toggle()
        deduceCurrentMode()
        updateJogsDisplay()
    }
}

// MARK: - SettingsSegmentedControlDelegate
extension SettingsControlModeCell: SettingsSegmentedControlDelegate {
    func settingsSegmentedControlDidChange(sender: SettingsSegmentedControl, selectedSegmentIndex: Int) {
        if sender == zoomExpoSegmentedControl {
            let evTriggerSettings = selectedSegmentIndex == 0 ? false : true
            LogEvent.log(.button(item: LogEvent.LogKeyControlsSettings.evTrigger,
                                 value: String(evTriggerSettings)))

            Defaults.evTriggerSetting = evTriggerSettings
        } else if sender == joystickModeSegmentedControl {
            let isSpecialMode = selectedSegmentIndex == 0 ? false : true
            LogEvent.log(.button(item: LogEvent.LogKeyControlsSettings.special,
                                 value: String(isSpecialMode)))

            self.isSpecialMode = isSpecialMode
        }
        deduceCurrentMode()
        updateJogsDisplay()
    }
}

// MARK: - Private Funcs
private extension SettingsControlModeCell {
    /// Inits the view.
    func initView() {
        joystickModeStackView.customCornered(corners: [.allCorners],
                                             radius: Style.largeCornerRadius,
                                             backgroundColor: ColorName.white.color,
                                             borderColor: .clear)
        joystickModeLabel.text = L10n.settingsControlsOptionJoystickMode
        setupZoomExpoSegmentedControl()
        setupJoystickModeSegmentedControl()
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

        setupJoystickModeSegmentedControl()
        updateJogsDisplay()
    }

    /// Updates jogs display regarding current mode.
    func updateJogsDisplay() {
        let style: ActionButtonStyle = currentMode.jogsInversed ? .validate : .default2
        inverseJoystickButton.setup(image: Asset.Settings.Controls.reverseJoys.image.withRenderingMode(.alwaysTemplate),
                                    title: L10n.settingsControlsOptionInverseJoys,
                                    style: style)
        joystickImage.image = currentMode.getJoystickImage(isRegularSizeClass: isRegularSizeClass)
        jogsInversed = currentMode.jogsInversed
        isSpecialMode = currentMode.isSpecialMode
        updateJoystickLabels()
    }

    /// Deduces current mode regarding states.
    func deduceCurrentMode() {
        if !isSpecialMode && !jogsInversed {
            currentMode = .mode1
        } else if !isSpecialMode && jogsInversed {
            currentMode = .mode1Inversed
        } else if isSpecialMode && !jogsInversed {
            currentMode = .mode2
        } else if isSpecialMode && jogsInversed {
            currentMode = .mode2Inversed
        }

        viewModel?.updateRemoteMapping(withMode: currentMode)
    }

    /// Update joystick labels regarding the current mode.
    func updateJoystickLabels() {
        controllerCameraLabel.text = currentMode.controllerCameraText
        controllerLeftJoystickLabel.text = currentMode.leftJoystickText
        hudLeftJoystick.text = currentMode.leftJoystickText
        controllerRightJoystickLabel.text = currentMode.rightJoystickText
        hudRightJoystick.text = currentMode.rightJoystickText
        hudZoom.text = L10n.settingsControlsMappingZoom
        controllerSpeedModeLabel.text = L10n.settingsControlsMappingReset
        controllerRecordLabel.text = L10n.settingsControlsMappingRecord
        hudCameraLabel.text = L10n.settingsControlsMappingCamera
    }

    /// Sets up zoom exposure segmented control.
    func setupZoomExpoSegmentedControl() {
        let selectedSegmentIndex = !Defaults.evTriggerSetting ? 0 : 1
        let zoomSegment = SettingsSegment(title: L10n.settingsControlsMappingZoom, disabled: false, image: nil)
        let expoSegment = SettingsSegment(title: L10n.settingsControlsMappingExposure, disabled: false, image: nil)
        let segmentModel = SettingsSegmentModel(segments: [zoomSegment, expoSegment],
                                                selectedIndex: selectedSegmentIndex,
                                                isBoolean: false)
        zoomExpoSegmentedControl.segmentModel = segmentModel
        zoomExpoSegmentedControl.backgroundColor = ColorName.whiteAlbescent.color
        zoomExpoSegmentedControl.delegate = self
    }

    /// Sets up joystick mode segmented control.
    func setupJoystickModeSegmentedControl() {
        let selectedSegmentIndex = !currentMode.isSpecialMode ? 0 : 1
        let modes = [1, 2]
        let segments = modes.map {
            SettingsSegment(title: L10n.settingsControlsOptionJoystickModeNumber($0), disabled: false, image: nil)
        }
        let segmentModel = SettingsSegmentModel(segments: segments,
                                                selectedIndex: selectedSegmentIndex,
                                                isBoolean: false)
        joystickModeSegmentedControl.segmentModel = segmentModel
        joystickModeSegmentedControl.delegate = self
    }
}
