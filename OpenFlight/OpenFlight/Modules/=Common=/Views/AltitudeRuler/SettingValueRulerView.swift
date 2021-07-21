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
import Reusable

// MARK: - Protocols
/// Delegate for custom setting ruler view.
public protocol SettingValueRulerViewDelegate: AnyObject {
    /// Called when ruler value changed.
    ///
    /// - Parameters:
    ///     - value: current value
    func valueDidChange(_ value: Double)
}

// MARK: - Public Enums
/// Describes ruler orientation mode.
public enum RulerOrientation {
    case horizontal
    case vertical

    public static var defaultValue: RulerOrientation {
        return .vertical
    }

    /// Returns true if the current orientation is the horizontal one.
    var isHorizontal: Bool {
        return self == .horizontal
    }
}

/// Describes ruler display.
public enum RulerDisplayType {
    case number
    case string

    public static var defaultValue: RulerDisplayType {
        return .number
    }

    var bgColor: UIColor {
        switch self {
        case .number:
            return ColorName.clear.color
        case .string:
            return ColorName.greyDark60.color
        }
    }

    var selectedBgColor: UIColor {
        switch self {
        case .number:
            return ColorName.clear.color
        case .string:
            return ColorName.greenPea50.color
        }
    }

    var textColor: UIColor {
        ColorName.white.color
    }

    var selectedTextColor: UIColor {
        switch self {
        case .number:
            return ColorName.white.color
        case .string:
            return ColorName.greenSpring.color
        }
    }

    var shouldDisplaySelector: Bool {
        switch self {
        case .number:
            return true
        case .string:
            return false
        }
    }
}

// MARK: - Public Structs
/// Model for `SettingValueRuler`.
public struct SettingValueRulerModel {
    var value: Double = 0.0
    var title: String = ""
    var range: [Double] = []
    var rangeDescriptions: [String]
    var rangeImages: [UIImage]
    var unit: UnitType = .distance
    var orientation: RulerOrientation = .defaultValue
    var displayType: RulerDisplayType = .defaultValue

    // MARK: - Init
    public init(value: Double = 0.0,
                title: String = "",
                range: [Double] = [],
                rangeDescriptions: [String] = [],
                rangeImages: [UIImage] = [],
                unit: UnitType = .distance,
                orientation: RulerOrientation = RulerOrientation.defaultValue,
                displayType: RulerDisplayType = RulerDisplayType.defaultValue) {
        self.value = value
        self.title = title
        self.range = range
        self.rangeDescriptions = rangeDescriptions
        self.rangeImages = rangeImages
        self.unit = unit
        self.orientation = orientation
        self.displayType = displayType
    }

    // MARK: - Private Properties
    fileprivate var values: [Double] {
        return orientation.isHorizontal ? range : range.reversed()
    }
    fileprivate var valuesDescription: [String]? {
        guard rangeDescriptions.count == range.count else { return nil }

        return orientation.isHorizontal ? rangeDescriptions : rangeDescriptions.reversed()
    }
}

/// Custom setting ruler view.
public final class SettingValueRulerView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionContainerView: UIView!
    @IBOutlet private weak var verticalSelectionView: UIView!
    @IBOutlet private weak var horizontalSelectionView: UIView!

    // MARK: - Public Properties
    public var model: SettingValueRulerModel = SettingValueRulerModel() {
        didSet {
            collectionView.reloadData()
            collectionView.scrollToItem(at: indexPathForSelectedValue,
                                        at: orientation.isHorizontal
                                            ? .centeredHorizontally
                                            : .centeredVertically,
                                        animated: true)
            titleLabel.text = model.title
            if model.displayType.shouldDisplaySelector == false {
                horizontalSelectionView.isHidden = true
                verticalSelectionView.isHidden = true
            } else {
                verticalSelectionView.isHidden = orientation.isHorizontal
                horizontalSelectionView.isHidden = !verticalSelectionView.isHidden
            }
        }
    }
    public weak var delegate: SettingValueRulerViewDelegate?

    // MARK: - Private Properties
    private var indexPathForSelectedValue: IndexPath {
        return IndexPath(row: model.values.firstIndex(of: model.value) ?? 0, section: 0)
    }
    /// Property which updates the ruler view according to its orientation.
    private var orientation: RulerOrientation = .vertical

    // MARK: - Private Enums
    private enum Constants {
        static let gradientBorderColor: CGColor = UIColor.clear.cgColor
        static let gradientCentralColor: CGColor = ColorName.white.color.cgColor
        static let gradientStartingPoint: CGPoint = CGPoint(x: 0.0, y: 0.5)
        static let gradientEndPoint: CGPoint = CGPoint(x: 1.0, y: 0.5)
        static let largeCellSize: CGSize = CGSize(width: 66.0, height: 48.0)
        static let cellSize: CGSize = CGSize(width: 44.0, height: 40.0)
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInitSettingValueRulerView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitSettingValueRulerView()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - orientation: ruler view orientation
    init(orientation: RulerOrientation = .vertical) {
        self.orientation = orientation
        super.init(frame: CGRect.zero)
        self.commonInitSettingValueRulerView()
    }

    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if orientation.isHorizontal {
            self.collectionView.contentInset = UIEdgeInsets(top: 0.0,
                                                            left: self.collectionView.frame.size.width/2.0 - self.safeAreaInsets.left,
                                                            bottom: 0.0,
                                                            right: (self.collectionView.frame.size.width)/2.0 - self.safeAreaInsets.right)
            self.collectionView.scrollToItem(at: indexPathForSelectedValue,
                                             at: .centeredHorizontally,
                                             animated: false)
        } else {
            self.collectionView.contentInset = UIEdgeInsets(top: self.collectionView.frame.size.height/2.0,
                                                            left: 0.0,
                                                            bottom: self.collectionView.frame.size.height/2.0,
                                                            right: 0.0)
            self.collectionView.scrollToItem(at: indexPathForSelectedValue,
                                             at: .centeredVertically,
                                             animated: true)
        }
        addGradientLayer()
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        // FIXME: find better way to handle case where notch is left-sided, settings
        // are opened first, and then a waypoint or point of interest  is selected
        DispatchQueue.main.async {
            self.updateValue(indexPath: self.indexPathForSelectedValue)
        }
    }
}

// MARK: - Private Funcs
private extension SettingValueRulerView {
    /// Common init.
    func commonInitSettingValueRulerView() {
        self.loadNibContent()
        collectionView.register(cellType: SettingValueRulerCollectionViewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        if !orientation.isHorizontal {
            addBlurEffect()
        } else {
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            collectionView.collectionViewLayout = layout
        }
        titleLabel.isHidden = orientation.isHorizontal
        titleLabel.makeUp()
        verticalSelectionView.isHidden = orientation.isHorizontal
        horizontalSelectionView.isHidden = !verticalSelectionView.isHidden
    }

    /// Adds gradient layer over collection.
    func addGradientLayer() {
        guard model.displayType != .string else { return }

        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = collectionContainerView.bounds
        gradientLayer.colors = [Constants.gradientBorderColor,
                                Constants.gradientCentralColor,
                                Constants.gradientCentralColor,
                                Constants.gradientBorderColor]
        if orientation.isHorizontal {
            // Inits points for left to right gradient in horizontal mode intead of default values.
            gradientLayer.startPoint = Constants.gradientStartingPoint
            gradientLayer.endPoint = Constants.gradientEndPoint
        }
        collectionContainerView?.layer.mask = gradientLayer
    }

    /// Updates ruler value if it has changed, and scrolls to index.
    ///
    /// - Parameters:
    ///    - indexPath: indexPath of the selection
    func updateValue(indexPath: IndexPath) {
        guard indexPath.row < model.values.count else { return }

        let newValue = model.values[indexPath.row]
        if newValue != model.value {
            model.value = newValue
            delegate?.valueDidChange(newValue)
        }
        collectionView.scrollToItem(at: indexPath,
                                    at: orientation.isHorizontal
                                        ? .centeredHorizontally
                                        : .centeredVertically,
                                    animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension SettingValueRulerView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return model.range.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as SettingValueRulerCollectionViewCell
        // Setup content.
        if model.displayType == .string,
           model.rangeDescriptions.count > indexPath.row {
            let text = model.rangeDescriptions[indexPath.row]
            let image: UIImage? = model.rangeImages.count > indexPath.row ? model.rangeImages[indexPath.row] : nil
            cell.setup(text: text, image: image)
        } else {
            cell.setup(value: model.values[indexPath.row],
                       unit: model.unit)
        }

        // Setup display.
        if model.value == model.values[indexPath.row] {
            // Selected.
            cell.setupDisplay(textColor: model.displayType.selectedTextColor,
                              backgroundColor: model.displayType.selectedBgColor)
        } else {
            // Not selected.
            cell.setupDisplay(textColor: model.displayType.textColor,
                              backgroundColor: model.displayType.bgColor)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension SettingValueRulerView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateValue(indexPath: indexPath)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        let indexPath = orientation.isHorizontal
            ? collectionView.closestToHorizontalCenterIndexPath
            : collectionView.closestToVerticalCenterIndexPath
        updateValue(indexPath: indexPath ?? self.indexPathForSelectedValue)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath = orientation.isHorizontal
            ? collectionView.closestToHorizontalCenterIndexPath
            : collectionView.closestToVerticalCenterIndexPath
        updateValue(indexPath: indexPath ?? self.indexPathForSelectedValue)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SettingValueRulerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        if model.displayType == .string {
            return Constants.largeCellSize
        } else {
            return Constants.cellSize
        }
    }
}
