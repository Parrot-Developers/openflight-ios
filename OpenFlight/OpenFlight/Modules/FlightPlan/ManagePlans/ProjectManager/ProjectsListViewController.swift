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

/// Manages a flight plan list.
final class ProjectsListViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var emptyProjectsTitleLabel: UILabel!
    @IBOutlet private weak var emptyProjectsDescriptionLabel: UILabel!
    @IBOutlet private weak var emptyLabelStack: UIStackView!
    var viewModel: ProjectsListViewModel!

    // MARK: - Internal Properties
    private var cancellables = [AnyCancellable]()

    // MARK: - Setup
    static func instantiate(viewModel: ProjectsListViewModel) -> ProjectsListViewController {
        let viewController = StoryboardScene.ProjectsList.projectsListViewController.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }

    func setupViewModel(_ viewModel: ProjectsListViewModel) {
        self.viewModel = viewModel
    }

    private func bindViewModel() {
        viewModel.$filteredProjects
            .receive(on: RunLoop.main)
            .sink { [weak self] projects in
                guard let self = self else { return }

                self.collectionView?.reloadData()
                self.emptyLabelStack.isHidden = !projects.isEmpty
                self.scrollToSelectedProject()
            }
            .store(in: &cancellables)

        viewModel.$selectedProject
            .receive(on: RunLoop.main)
            .sink { [weak self] _  in
                guard let collectionView = self?.collectionView else { return }
                collectionView.reloadData()
            }
            .store(in: &cancellables)

      }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(cellType: ProjectCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        emptyProjectsTitleLabel.text = L10n.flightPlanEmptyListTitle
        emptyProjectsDescriptionLabel.text = L10n.flightPlanEmptyListDesc
        bindViewModel()

        // Add double tap gesture recognizer for project quick open action.
        collectionView.addDoubleTapRecognizer(target: self, action: #selector(didDoubleTap))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    func scrollToSelectedProject() {
        if let index = viewModel.getSelectedProjectIndex() {
            collectionView.scrollToItem(at: IndexPath(row: index, section: 0),
                                              at: .centeredVertically,
                                              animated: false)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ProjectsListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.filteredProjects.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as ProjectCell
        let project = viewModel.filteredProjects[indexPath.row]
        let projectCellModel = ProjectCellModel(project: project,
                                                isSelected: viewModel.isProjectSelected(project),
                                                projectManager: viewModel.manager)
        cell.configureCell(viewModel: projectCellModel)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension ProjectsListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let project = viewModel.filteredProjects[indexPath.row]
        viewModel.isProjectSelected(project) ? viewModel.didDeselectProject() : viewModel.didSelect(project: project)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ProjectsListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        collectionView.gridItemSize()
    }
}

extension ProjectsListViewController {
    /// Collectionview's double tap action.
    /// Opens a project if a double tap is detected on corresponding cell.
    ///
    /// - Parameters:
    ///    - sender: The double tap gesture recognizer.
    @objc func didDoubleTap(_ sender: UIGestureRecognizer) {
        // Get cell's index.
        guard let index = collectionView.indexPathForItem(at: sender.location(in: collectionView))?.item else { return }
        // Update VM with double tap event.
        viewModel.didDoubleTap(project: viewModel.filteredProjects[index])
    }
}
