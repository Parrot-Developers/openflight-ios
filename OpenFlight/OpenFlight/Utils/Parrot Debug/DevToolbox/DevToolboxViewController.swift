// Copyright (C) 2021 Parrot Drones SAS
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
import GroundSdk
import Reusable

/// Parrot DevToolbox screen to show DevToolbox content.
class DevToolboxViewController: UITableViewController {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var currentDroneWatcher = CurrentDroneWatcher()
    private var drone: Drone?
    private var devToolboxRef: Ref<DevToolbox>?
    private var dataSource: [DebugSetting] = []

    // MARK: - Private Enums
    private enum Constants {
        static let smallCellHeight: CGFloat = 44.0
        static let bigCellHeight: CGFloat = 84.0
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(cellType: DevToolboxCell.self)

        currentDroneWatcher.start { [weak self] drone in
            self?.drone = drone
            self?.devToolboxRef = drone.getPeripheral(Peripherals.devToolbox) { [weak self] devToolbox in
                guard let devToolbox = devToolbox else { return }

                self?.dataSource = devToolbox.debugSettings
                self?.tableView.reloadData()
            }
        }
    }
}

// MARK: - TableView dataSource
extension DevToolboxViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let setting = (dataSource[indexPath.row] as? NumericDebugSetting),
            !setting.readOnly, setting.range != nil {
            return Constants.bigCellHeight
        } else {
            return Constants.smallCellHeight
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DevToolboxCell
        cell.update(withEntry: dataSource[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
}
