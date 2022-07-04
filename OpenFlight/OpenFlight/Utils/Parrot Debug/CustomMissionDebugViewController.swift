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
import SwiftyUserDefaults

class CustomMissionDebugViewController: UIViewController {

    @IBOutlet private weak var vehicleCalibrationButton: UIButton!
    @IBOutlet private weak var enableCalibrationSwitch: UISwitch!
    @IBOutlet private weak var calibrationExistImage: UIImageView!

    private weak var coordinator: ParrotDebugCoordinator?

    override func viewDidLoad() {
        super.viewDidLoad()
        calibrationExistImage.isHidden = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changeExistCalibration),
                                               name: .customCalibrationExist,
                                               object: nil)

    }

    override func viewWillAppear(_ animated: Bool) {
        enableCalibrationSwitch.isOn = Defaults.activatedCalibration
        super.viewWillAppear(animated)
    }

    static func instantiate(coordinator: ParrotDebugCoordinator) -> CustomMissionDebugViewController {
        let viewController = StoryboardScene.CustomMissionDebug.initialScene.instantiate()
        viewController.coordinator = coordinator
        return viewController
    }

    @objc func changeExistCalibration(_ notification: Notification) {
        if let calibrationExist = notification.object as? Bool {
            calibrationExistImage.isHidden = false
            calibrationExistImage.image = calibrationExist ? Asset.Common.Checks.icChecked.image : Asset.Remote.icErrorUpdate.image
        }
    }

    @IBAction func closeView(_ sender: Any) {
        coordinator?.dismiss()
    }

    // Will be removed
    @IBAction func removeCalibration(_ sender: UIButton) {
        NotificationCenter.default.post(.init(name: .removeCustomMissionCalibration))
    }

    @IBAction func enableCalibration(_ sender: UISwitch) {
        Defaults.activatedCalibration = sender.isOn
        NotificationCenter.default.post(.init(name: .enableCustomCalibration, object: sender.isOn))
    }
}
