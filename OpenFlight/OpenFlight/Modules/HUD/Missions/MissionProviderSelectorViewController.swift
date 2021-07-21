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

/// Class that manages mission launcher menu to choose between avaialable missions provider.
final class MissionProviderSelectorViewController: UIViewController {

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel! {
        didSet {
            titleLabel.makeUp(with: .regular, and: ColorName.sambuca)
            titleLabel.text = L10n.missionSelectLabel.uppercased()
        }
    }
    @IBOutlet private weak var tableView: UITableView! {
        didSet {
            tableView.register(cellType: MissionItemCell.self)
        }
    }

    // MARK: - Internal Properties
    var viewModel: MissionProviderSelectorViewModel!

    // MARK: - Private Properties
    private var items = [MissionItemCellModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.itemsPublisher.sink { [unowned self] in
            items = $0
            tableView.reloadData()
        }
        .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension MissionProviderSelectorViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: MissionItemCell.self)
        let model = items[indexPath.row]
        cell.setup(with: model)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MissionProviderSelectorViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        LogEvent.logAppEvent(itemName: items[indexPath.row].title.description,
                             logType: .simpleButton)
        viewModel.userDidTap(on: indexPath.row)
    }
}
