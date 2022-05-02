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
import Reusable
import Combine

/// Header menu TableViewCell.
final class HeaderMenuTableViewCell: UITableViewHeaderFooterView, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet private weak var sectionTitle: UILabel!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var leadingConstraint: NSLayoutConstraint!
    private var tapGestureSubscriberHandle: AnyCancellable?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()
        separatorView.backgroundColor = ColorName.defaultTextColor20.color
        sectionTitle.makeUp(with: .caps, color: .disabledTextColor)
        bottomConstraint.constant = Layout.mainSpacing(isRegularSizeClass)
        topConstraint.constant = Layout.mainSpacing(isRegularSizeClass)
        leadingConstraint.constant = Layout.mainPadding(isRegularSizeClass)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        tapGestureSubscriberHandle?.cancel()
    }

    // MARK: - Public Funcs
    func setup(with title: String?, action: (() -> Void)? = nil) {
        sectionTitle.text = title
        sectionTitle.isHidden = title?.isEmpty ?? true
        if title?.isEmpty ?? true {
            sectionTitle.isHidden = true
            topConstraint.constant = 0
        } else {
            sectionTitle.isHidden = false
            topConstraint.constant = Layout.mainSpacing(isRegularSizeClass)
        }

        if let action = action {
            tapGestureSubscriberHandle = tapGesturePublisher.sink { _ in
                action()
            }
        }
    }
}
