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

/// Circle class used to display round view with border.
class CircleClass: UIView {

    private enum Constants {
        static let borderSize = 1.0
        static let fontSize = 13.0
    }

    private var outsideRound = UIView()
    private var insideRound = UIView()
    private var label = UILabel()
    private var imageView: UIImageView?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override var frame: CGRect {
        didSet {
            updateSize()
        }
    }

    func commonInit() {
        backgroundColor = .clear
        addSubview(outsideRound)
        addSubview(insideRound)
        outsideRound.layer.masksToBounds = true
        insideRound.layer.masksToBounds = true
        updateSize()
    }

    func setText(_ text: String) {
        label.textColor = .white
        label.text = text
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.font = UIFont.rajdhaniSemiBold(size: Constants.fontSize)
        label.layer.shadowOffset = CGSize(width: 2, height: 2)
        label.layer.shadowColor = CGColor.init(srgbRed: 0, green: 0, blue: 0, alpha: 1)
        addSubview(label)
    }

    func updateSize() {
        outsideRound.layer.cornerRadius = frame.size.width / 2.0
        insideRound.layer.cornerRadius =  (frame.size.width - Constants.borderSize * 2) / 2.0
        outsideRound.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
        insideRound.frame = CGRect(x: Constants.borderSize, y: Constants.borderSize,
                                   width: frame.size.width - Constants.borderSize * 2,
                                   height: frame.size.height - Constants.borderSize * 2)
        let newFrame = CGRect(x: 0,
                              y: 0,
                              width: frame.size.width,
                              height: frame.size.height)
        label.frame = newFrame
        imageView?.frame = newFrame
    }

    func set(image: UIImage?) {
        imageView = UIImageView(image: image)
        imageView?.frame = CGRect(x: 0,
                                  y: 0,
                                  width: frame.size.width,
                                  height: frame.size.height)
        addSubview(imageView)
    }

    func setColor(borderColor: UIColor, insideColor: UIColor) {
        outsideRound.backgroundColor = borderColor
        insideRound.backgroundColor = insideColor
    }
}
