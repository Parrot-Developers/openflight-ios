//    Copyright (C) 2023 Parrot Drones SAS
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

/// Overlay for the home icon in the stream view
class HomeStreamView: OverlayStreamView {
    private enum Constants {
        static let alpha = 0.6
    }
    private var homeImageView: UIImageView = UIImageView()
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    private var contentZone: CGRect!

    var viewModel: HomeStreamViewModel = HomeStreamViewModel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentZone = frame
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentZone = frame
        setup()
    }

    override func update(frame: CGRect) {
        super.update(frame: frame)
        contentZone = frame
    }

    private func setup() {
        homeImageView.alpha = Constants.alpha
        homeImageView.isHidden = true
        addSubview(homeImageView)
        viewModel = HomeStreamViewModel()

        viewModel.$homeImage
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] homeImage in
                guard let self = self,
                      let homeImage = homeImage
                else { return }

                self.homeImageView.image = homeImage
                self.homeImageView.frame.size = homeImage.size
            }
            .store(in: &cancellables)

        viewModel.$homePosition
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] homePosition in
                guard let self = self else { return }
                if let homePosition = homePosition {
                    let center = self.pointInStreamView(point: homePosition)
                    let size = self.homeImageView.frame.size
                    let origin = CGPoint(x: center.x - size.width/2 + self.contentZone.origin.x, y: center.y - size.height/2 + self.contentZone.origin.y)
                    self.homeImageView.frame.origin = origin
                    self.homeImageView.isHidden = false
                } else {
                    self.homeImageView.isHidden = true
                }
            }
            .store(in: &cancellables)
    }

    /// Converts a normalized point into stream view coordinates.
    /// Override method to use contentZone instead of frame.
    ///
    /// - Parameters:
    ///    - point: the point to convert
    /// - Returns: the converted point
    override func pointInStreamView(point: CGPoint) -> CGPoint {
        return CGPoint(x: contentZone.width * point.x, y: contentZone.height * point.y)
    }
}
