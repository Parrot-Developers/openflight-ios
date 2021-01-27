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

/// View Controller wich is in charge of displaying Live Streaming panel.
final class LiveStreamingViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var prioritySegmentedControl: UISegmentedControl!
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var topViewConstraint: NSLayoutConstraint!

    // MARK: - Private Properties
    private weak var coordinator: Coordinator?
    private var selectedPriority: StreamingPriority {
        StreamingPriority.type(at: prioritySegmentedControl?.selectedSegmentIndex ?? 0)
    }
    private var viewModel: LiveStreamingViewModel?
    private var streamingUrlList: [UrlLiveStreaming] = [] {
        didSet {
            updateDataSource()
        }
    }

    // MARK: - Private Enums
    private enum Constants {
        static let cellHeight: CGFloat = 60.0
        static let defaultAnimationDuration: TimeInterval = 0.9
        static let topConstraintRatioKeyboardShown: CGFloat = 0.05
        static let topConstraintRatioKeyboardHidden: CGFloat = 0.4
    }

    // MARK: - Setup
    static func instantiate(coordinator: Coordinator) -> LiveStreamingViewController {
        let viewController = StoryboardScene.LiveStreaming.liveStreamingViewController.instantiate()
        viewController.coordinator = coordinator

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initViewModel()
        initView()
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
private extension LiveStreamingViewController {
    @IBAction func closeButtonTouchedUpInside(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Private Funcs
private extension LiveStreamingViewController {
    /// Init the view.
    func initView() {
        titleLabel.makeUp(with: .huge)
        titleLabel.text = L10n.liveStreamingLiveStreaming
        topViewConstraint.constant = Constants.topConstraintRatioKeyboardHidden * self.view.frame.height
        setupPrioritySegmentedControl()
        panelView.addBlurEffect()

        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.register(cellType: LiveStreamingTableViewCell.self)
        tableView.register(cellType: LiveStreamingAddTableViewCell.self)
    }

    /// Init live streaming ViewModel.
    func initViewModel() {
        viewModel = LiveStreamingViewModel(stateDidUpdate: { [weak self] state in
            self?.streamingUrlList = state.streamingUrlList
        })
        streamingUrlList = viewModel?.state.value.streamingUrlList ?? []
    }

    /// Setup priority segmented control.
    func setupPrioritySegmentedControl() {
        prioritySegmentedControl.customMakeup(selectedBackgroundColor: ColorName.greenSpring20,
                                              selectedFontColor: ColorName.greenSpring)
        prioritySegmentedControl.cornerRadiusedWith(backgroundColor: ColorName.black.color,
                                                    borderColor: ColorName.white20.color,
                                                    radius: Style.largeCornerRadius,
                                                    borderWidth: Style.mediumBorderWidth)
        prioritySegmentedControl.removeAllSegments()
        for panelType in StreamingPriority.allCases {
            prioritySegmentedControl.insertSegment(withTitle: panelType.title,
                                                   at: prioritySegmentedControl.numberOfSegments,
                                                   animated: false)
        }
        prioritySegmentedControl.selectedSegmentIndex = selectedPriority.rawValue
    }

    /// Update tableView data source.
    func updateDataSource() {
        viewModel?.state.value.isNewUrlAdded = false
        tableView.reloadData()
    }
}

// MARK: - LiveStreamingViewController Data Source
extension LiveStreamingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (viewModel?.state.value.streamingUrlList.count ?? 1) + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell = UITableViewCell()
        if let state = viewModel?.state.value,
            indexPath.row < streamingUrlList.count {
            cell = tableView.dequeueReusableCell(withIdentifier: LiveStreamingTableViewCell.reuseIdentifier, for: indexPath)
            guard let cell = cell as? LiveStreamingTableViewCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            cell.fill(state: state.streamingUrlList[indexPath.row])
        } else if viewModel?.state.value.isNewUrlAdded == false {
            cell = tableView.dequeueReusableCell(withIdentifier: LiveStreamingAddTableViewCell.reuseIdentifier, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: LiveStreamingTableViewCell.reuseIdentifier, for: indexPath)
            guard let cell = cell as? LiveStreamingTableViewCell else {
                return UITableViewCell()
            }
            cell.delegate = self
            cell.fill(state: nil)
        }
        cell.backgroundColor = nil
        cell.selectionStyle = .none

        return cell
    }
}

// MARK: - LiveStreamingViewController Delegate
extension LiveStreamingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel?.state.value.isNewUrlAdded == false,
            let state = viewModel?.state.value,
            indexPath.row >= state.streamingUrlList.count else {
                return
        }
        viewModel?.state.value.isNewUrlAdded = true
        tableView.reloadData()
    }
}

// MARK: - LiveStreamingViewController Table View Delegate
extension LiveStreamingViewController: LiveStreamingTableViewCellDelegate {
    func updateTopConstraint(isKeyboardHidden: Bool) {
        UIView.animate(withDuration: Constants.defaultAnimationDuration) {
            let value = isKeyboardHidden
                ? Constants.topConstraintRatioKeyboardHidden * self.view.frame.height
                : Constants.topConstraintRatioKeyboardShown * self.view.frame.height
            self.topViewConstraint.constant = value
            self.view.layoutIfNeeded()
        }
    }

    func deleteNotRegisteredUrl() {
        updateDataSource()
    }
}
