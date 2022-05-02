//    Copyright (C) 2021 Parrot Drones SAS
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
import Reusable

class DashboardProjectManagerCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var projectsCountLabel: UILabel!
    @IBOutlet weak var fpProjectIcon: UIImageView!
    @IBOutlet weak var fpProjectsCountLabel: UILabel!
    @IBOutlet weak var otherProjectIcon: UIImageView!
    @IBOutlet weak var otherProjectsCountLabel: UILabel!
    @IBOutlet private weak var syncLoaderImageView: UIImageView!

    // MARK: - Private vars

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum Constants {
        static let defaultProjectCount: Int = 0
    }

    // MARK: - Override Funcs
    override func prepareForReuse() {
        super.prepareForReuse()
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        resetLabels()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        initView()
    }

    // MARK: - Internal Funcs
    /// Sets up the cell with his model.
    ///
    /// - Parameters:
    ///     - viewModel: cell's view model
    func setup(viewModel: DashboardProjectManagerCellModel) {
        titleLabel.text = L10n.flightPlanProjects
        viewModel.summary
            .sink { [weak self] in
                self?.projectsCountLabel.text = String($0.numberOfProjects)
                self?.fpProjectsCountLabel.text = String($0.numberOfFPProjects)
                self?.otherProjectsCountLabel.text = String($0.numberOfOtherProjects)
                self?.otherProjectIcon.image = $0.otherProjectsIcon
                self?.otherProjectIcon.isHidden = $0.otherProjectsIcon == nil
                self?.otherProjectsCountLabel.isHidden = $0.otherProjectsIcon == nil
            }
            .store(in: &cancellables)

        viewModel.isSynchronizingData
            .sink { [weak self] isSync in
                guard let self = self else { return }
                isSync ? self.syncLoaderImageView.startRotate() : self.syncLoaderImageView.stopRotate()
                self.syncLoaderImageView.isHidden = !isSync
            }
            .store(in: &cancellables)
    }

}

// MARK: - Private Funcs
private extension DashboardProjectManagerCell {
    func initView() {
        resetLabels()
   }

    func resetLabels() {
        projectsCountLabel.text = String(Constants.defaultProjectCount)
        fpProjectsCountLabel.text = String(Constants.defaultProjectCount)
        otherProjectsCountLabel.text = String(Constants.defaultProjectCount)
        otherProjectIcon.isHidden = true
        otherProjectsCountLabel.isHidden = true
   }
}
