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

/// A UIStackView with right side panel UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
public class RightSidePanelStackView: MainContainerStackView {
    override func setupView() {
        super.setupView()
        widthAnchor.constraint(equalToConstant: Layout.sidePanelWidth(isRegularSizeClass)).isActive = true
        screenBorders = [.bottom]
    }
}

/// A UIView with right side panel UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class RightSidePanelView: MainContainerView {
    override func setupView() {
        super.setupView()
        widthAnchor.constraint(equalToConstant: Layout.sidePanelWidth(isRegularSizeClass)).isActive = true
        screenBorders = [.bottom]
        backgroundColor = ColorName.defaultBgcolor.color
    }
}

/// A UIStackView with left side panel UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class LeftSidePanelStackView: MainContainerStackView {
    override func setupView() {
        super.setupView()
        widthAnchor.constraint(equalToConstant: Layout.leftSidePanelWidth(isRegularSizeClass)).isActive = true
        screenBorders = [.left, .bottom]
    }
}

/// A UIView with left side panel UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class LeftSidePanelView: MainContainerView {
    override func setupView() {
        super.setupView()
        widthAnchor.constraint(equalToConstant: Layout.leftSidePanelWidth(isRegularSizeClass)).isActive = true
        screenBorders = [.left, .bottom]
        backgroundColor = ColorName.defaultBgcolor.color
    }
}

/// A UIView with navigation left side panel UI layout.
/// (Modularity purpose only: share `Layout` constants amongst different view controllers.)
class NavigationLeftSidePanelView: MainContainerView {
    override func setupView() {
        super.setupView()
        widthAnchor.constraint(equalToConstant: Layout.navigationLeftSidePanelWidth(isRegularSizeClass)).isActive = true
        screenBorders = [.left, .bottom]
        backgroundColor = ColorName.defaultBgcolor.color
    }
}
