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

// MARK: - Private Enums
private enum Constants {
    static let gradientWidthDivider: CGFloat = 3.0
    static let gradientBorderColor: CGColor = UIColor.clear.cgColor
    static let gradientCentralColor: CGColor = ColorName.white.color.cgColor
    static let gradientStartX: CGFloat = 0.0
    static let gradientEndX: CGFloat = 1.0
    static let gradientY: CGFloat = 0.5
    static let pipeCellWidth: CGFloat = 24.0
    static let valueCellWidth: CGFloat = 58.0
}

/// Ruler bar displaying a mode associated to a `BarButtonState`.

// swiftlint:disable line_length
final class CenteredRulerBarView<T: BarButtonState>: UIView, NibOwnerLoadable, NibLoadable, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // swiftlint:enable line_length
    // MARK: - Outlets
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var selectionView: UIView!
    @IBOutlet private var selectionGraduations: [UIView]!

    // MARK: - Internal Properties
    static var nib: UINib {
        return UINib(nibName: "CenteredRulerBarView", bundle: Bundle.currentBundle(for: self))
    }
    weak var viewModel: BarButtonViewModel<T>? {
        didSet {
            viewModel?.state.valueChanged = { [weak self] _ in
                self?.updateModels()
                self?.collectionView.reloadData()
            }
            self.updateModels()
        }
    }
    /// Boolean for current ruler automatic state.
    var isAutomatic: Bool = true {
        didSet {
            selectionView.backgroundColor = (isAutomatic ? ColorName.white20 : ColorName.greenSpring20).color
            selectionGraduations.forEach {
                $0.backgroundColor = (isAutomatic ? ColorName.white : ColorName.greenSpring).color
            }
        }
    }

    // MARK: - Private Properties
    private var models = [BarButtonState]()
    private var indexPathForSelectedMode: IndexPath {
        return IndexPath(row: models.firstIndex(where: { $0.isSelected.value }) ?? 0, section: 0)
    }
    private var firstEnabledIndexPath: IndexPath? {
        guard let row = models.firstIndex(where: { $0.enabled }) else {
            return nil
        }
        return IndexPath(row: row, section: 0)
    }
    private var lastEnabledIndexPath: IndexPath? {
        guard let row = models.lastIndex(where: { $0.enabled }) else {
            return nil
        }
        return IndexPath(row: row, section: 0)
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitCenteredRulerBarView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitCenteredRulerBarView()
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        self.collectionView.contentInset = UIEdgeInsets(top: 0.0,
                                                        left: self.collectionView.frame.size.width/2,
                                                        bottom: 0.0,
                                                        right: self.collectionView.frame.size.width/2)
        self.addGradientLayer()
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return models.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as RulerBarLabelCollectionViewCell
        if let mode = models[indexPath.row].mode as? RulerDisplayable {
            cell.fill(with: mode, isEnabled: models[indexPath.row].enabled)
        }
        return cell
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateMode(indexPath: indexPath)
    }

    // MARK: - UIScrollViewDelegate
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else {
            return
        }
        // Select closest mode after a drag.
        let indexPath = collectionView.closestInteractiveToHorizontalCenterIndexPath ?? self.indexPathForSelectedMode
        LogEvent.logAppEvent(screen: LogEvent.EventLoggerScreenConstants.bottomBarHUD.name,
                             itemName: models[indexPath.row].mode?.logKey,
                             newValue: models[indexPath.row].mode?.key,
                             logType: .button)
        updateMode(indexPath: indexPath)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath: IndexPath
        if let closestInteractiveIndexPath = collectionView.closestInteractiveToHorizontalCenterIndexPath {
            indexPath = closestInteractiveIndexPath
        } else if let closestIndexPath = collectionView.closestToHorizontalCenterIndexPath {
            // Should rescroll to first or last if user overscrolls when value is already selected.
            if collectionView.isLast(indexPath: closestIndexPath), let lastEnabledIndexPath = lastEnabledIndexPath {
                indexPath = lastEnabledIndexPath
            } else if closestIndexPath == IndexPath(row: 0, section: 0), let firstEnabledIndexPath = firstEnabledIndexPath {
                indexPath = firstEnabledIndexPath
            } else {
                indexPath = indexPathForSelectedMode
            }
        } else {
            indexPath = indexPathForSelectedMode
        }
        updateMode(indexPath: indexPath)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let mode = models[indexPath.row].mode as? RulerDisplayable, mode.rulerText == Style.pipe {
            return CGSize(width: Constants.pipeCellWidth, height: collectionView.frame.height)
        } else {
            return CGSize(width: Constants.valueCellWidth, height: collectionView.frame.height)
        }
    }
}

// MARK: - Private Funcs
private extension CenteredRulerBarView {
    /// Common init.
    func commonInitCenteredRulerBarView() {
        self.loadNibContent()
        collectionView.register(cellType: RulerBarLabelCollectionViewCell.self)
        addGradientLayer()
    }

    /// Add horizontal gradient layer to view.
    func addGradientLayer() {
        let gradientLayer = CAGradientLayer()
        let gradientWidth = frame.width / Constants.gradientWidthDivider
        gradientLayer.frame = frame
        gradientLayer.colors = [Constants.gradientBorderColor,
                                Constants.gradientCentralColor,
                                Constants.gradientCentralColor,
                                Constants.gradientBorderColor]
        let startPoint = CGPoint(x: Constants.gradientStartX,
                                 y: Constants.gradientY)
        let endPoint = CGPoint(x: Constants.gradientEndX,
                               y: Constants.gradientY)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.locations = [NSNumber(value: Double(Constants.gradientStartX)),
                                   NSNumber(value: Double(gradientWidth / frame.width)),
                                   NSNumber(value: Double((frame.width - gradientWidth)/frame.width)),
                                   NSNumber(value: Double(Constants.gradientEndX))]
        superview?.layer.mask = gradientLayer
    }

    /// Update ruler models (data source).
    func updateModels() {
        guard let mode = viewModel?.state.value.mode else { return }
        models = type(of: mode).allValues.map {
            let itemKey = $0.key
            let itemState = CameraBarButtonState(mode: $0,
                                                 enabled: viewModel?.state.value.supportedModes?.contains(where: { mode in itemKey == mode.key }) == true,
                                                 isSelected: Observable(mode.key == $0.key))
            itemState.isSelected.valueChanged = { [weak self] isSelected in
                if isSelected, let mode = itemState.mode {
                    self?.viewModel?.update(mode: mode)
                }
            }
            return itemState
        }
        self.collectionView.scrollToItem(at: self.indexPathForSelectedMode,
                                         at: .centeredHorizontally,
                                         animated: true)
    }

    /// Update current mode and scroll to its position.
    ///
    /// - Parameters:
    ///    - indexPath: index path for new mode
    func updateMode(indexPath: IndexPath) {
        guard models.count > indexPath.row,
            let mode = models[indexPath.row].mode
            else {
                return
        }
        viewModel?.update(mode: mode)
        collectionView.scrollToItem(at: indexPath,
                                    at: .centeredHorizontally,
                                    animated: true)
    }
}
