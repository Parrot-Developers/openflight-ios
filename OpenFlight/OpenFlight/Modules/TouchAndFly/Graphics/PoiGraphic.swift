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

import Foundation

/// Point of interest graphic class.
class PoiGraphic: UIView {

    private var label = UILabel()
    private var image: UIImageView?

    private enum Constants {
        static let borderSize = 1.0
        static let fontSize = 13.0
    }

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        addDiamond()
    }

    override var frame: CGRect {
        didSet {
            updateSize()
        }
    }

    private func updateSize() {
        let newFrame = CGRect(x: 0,
                              y: 0,
                              width: frame.size.width,
                              height: frame.size.height)
        label.frame = newFrame
        bringSubviewToFront(label)
        image?.frame = newFrame
    }
    func setText(_ text: String) {
        label.textColor = .white
        label.text = text
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.rajdhaniSemiBold(size: Constants.fontSize)
        label.frame = CGRect(x: 0,
                             y: 0,
                             width: frame.size.width,
                             height: frame.size.height)

        label.layer.shadowOffset = CGSize(width: 2, height: 2)
        label.layer.shadowColor = CGColor.init(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        addSubview(label)
    }

    public override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    func addDiamond() {
        if image == nil {
            image = UIImageView(image: Asset.TouchAndFly.touchAndFlyPoi.image)
            image?.frame = self.frame
            addSubview(image)
        }
    }
}
