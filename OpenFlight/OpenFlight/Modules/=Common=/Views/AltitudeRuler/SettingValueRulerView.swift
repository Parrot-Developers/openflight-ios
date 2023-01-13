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

    /// Called when the ruler is being moved
    func scrollViewWillBeginMoving()

    /// Called when the ruler stops moving after a drag or a deceleration
    func scrollViewDidEndMoving()
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
    case warningNumber

    public static var defaultValue: RulerDisplayType {
        return .number
    }

    var bgColor: UIColor {
        return ColorName.clear.color
    }

    var selectedBgColor: UIColor {
        return ColorName.clear.color
    }

    var textColor: UIColor {
        ColorName.defaultTextColor.color
    }

    var selectedTextColor: UIColor {
        switch self {
        case .number, .warningNumber:
            return ColorName.white.color
        case .string:
            return ColorName.white.color
        }
    }

    var shouldDisplaySelector: Bool {
        return true
    }

    var selectorBackgroundColor: UIColor {
        switch self {
        case .number, .string:
            return ColorName.highlightColor.color
        case .warningNumber:
            return ColorName.warningColor.color
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
}

/// Custom setting ruler view.
public final class SettingValueRulerView: UIView, NibOwnerLoadable {
    // MARK: - Outlets
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionContainerView: UIView!
    @IBOutlet private weak var verticalSelectionView: UIView!
    @IBOutlet private(set) weak var horizontalSelectionView: UIView!
    @IBOutlet private weak var gradientBackground: UIView!
    @IBOutlet weak var centerLeftIndicatorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerRightIndicatorWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerTopIndicatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerBottomIndicatorHeightConstraint: NSLayoutConstraint!

    // MARK: - Public Properties
    public var model: SettingValueRulerModel = SettingValueRulerModel() {
        didSet {
            collectionView.reloadData()
            if indexPathForSelectedValue.row < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: indexPathForSelectedValue,
                                            at: orientation.isHorizontal
                                                ? .centeredHorizontally
                                                : .centeredVertically,
                                            animated: true)
            }
            titleLabel.text = model.title
            horizontalSelectionView.backgroundColor = model.displayType.selectorBackgroundColor
            verticalSelectionView.backgroundColor = model.displayType.selectorBackgroundColor
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
        let index = model.values.firstIndex(of: model.value) ??
        model.values.closestIndex(of: model.value) ?? 0

        return IndexPath(row: index, section: 0)
    }
    /// Property which updates the ruler view according to its orientation.
    private var orientation: RulerOrientation = .vertical

    // MARK: - Private Enums
    private enum Constants {
        static let gradientBorderColor: CGColor = UIColor.clear.cgColor
        static let gradientCentralColor: CGColor = ColorName.defaultBgcolor.color.cgColor
        static let gradientStartingPoint: CGPoint = CGPoint(x: 0.0, y: 0.5)
        static let gradientEndPoint: CGPoint = CGPoint(x: 1.0, y: 0.5)
    }

    // MARK: - Override Funcs
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInitSettingValueRulerView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInitSettingValueRulerView()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - orientation: ruler view orientation
    public init(orientation: RulerOrientation = .vertical) {
        self.orientation = orientation
        super.init(frame: CGRect.zero)
        commonInitSettingValueRulerView()
    }

    public override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        if orientation.isHorizontal {
            collectionView.contentInset = UIEdgeInsets(top: 0.0,
                                                       left: collectionView.frame.size.width/2.0 - safeAreaInsets.left,
                                                       bottom: 0.0,
                                                       right: (collectionView.frame.size.width)/2.0 - safeAreaInsets.right)
            if indexPathForSelectedValue.row < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: indexPathForSelectedValue,
                                            at: .centeredHorizontally,
                                            animated: false)
            }
        } else {
            collectionView.contentInset = UIEdgeInsets(top: collectionView.frame.size.height/2.0,
                                                       left: 0.0,
                                                       bottom: collectionView.frame.size.height/2.0,
                                                       right: 0.0)
            if indexPathForSelectedValue.row < collectionView.numberOfItems(inSection: 0) {
                collectionView.scrollToItem(at: indexPathForSelectedValue,
                                            at: .centeredVertically,
                                            animated: true)
            }
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

    ///  Cancels the update operation of the setting.
    ///
    /// This is used when there is a need to cancel an animation of the collection view immediately.
    /// If the ruler setting is currently animated, the new value will be the one visible in the center of the view.
    public func cancelUpdate() {
        self.updateValue(indexPath: self.indexPathForSelectedValue)
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
        titleLabel.makeUp(and: .defaultTextColor)
        verticalSelectionView.isHidden = orientation.isHorizontal
        horizontalSelectionView.isHidden = !verticalSelectionView.isHidden
    }

    /// Adds gradient layer over collection.
    func addGradientLayer() {
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

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginMoving()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        let indexPath = orientation.isHorizontal
            ? collectionView.closestToHorizontalCenterIndexPath
            : collectionView.closestToVerticalCenterIndexPath
        delegate?.scrollViewDidEndMoving()
        updateValue(indexPath: indexPath ?? indexPathForSelectedValue)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let indexPath = orientation.isHorizontal
            ? collectionView.closestToHorizontalCenterIndexPath
            : collectionView.closestToVerticalCenterIndexPath
        delegate?.scrollViewDidEndMoving()
        updateValue(indexPath: indexPath ?? indexPathForSelectedValue)
    }
}
