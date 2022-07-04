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

import UIKit
import Reusable
import GroundSdk
import Combine

final class HelloWorldDepthView: UIView, NibOwnerLoadable {

    @IBOutlet private weak var depthValueLabel: UILabel!

    // MARK: - Private Properties
    private let helloWorldMissionViewModel = HelloWorldMissionViewModel()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInitHelloWorldDepthView()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInitHelloWorldDepthView()
    }


    /// Retruns true if a `HelloWorldDepthView` is already in the View Controller hierarchy.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    /// - Returns: True if a `HelloWorldDepthView` is already in the View Controller hierarchy.
    static func isAlreadyDisplayed(in viewController: UIViewController) -> Bool {
        return viewController.view.subviews.contains(where: { $0 as? HelloWorldDepthView != nil })
    }

    /// Displays  the `HelloWorldDepthView` in a specific View Controller.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    func display(in viewController: UIViewController) {

        addConstraints(in: viewController)
    }
}

private extension HelloWorldDepthView {

    func commonInitHelloWorldDepthView() {
        loadNibContent()

        initViewModel()
    }

    /// Inits the view model.
    func initViewModel() {
        helloWorldMissionViewModel.$depthMean.removeDuplicates()
            .sink { [weak self] depthMean in
                guard let self = self else { return }
                self.depthValueLabel.text = String(format: "%.2f", depthMean)
            }
            .store(in: &cancellables)
    }

    /// Adds `HelloWorldDepthView` in a View Controller.
    ///
    /// - Parameters:
    ///     - viewController: The View Controller
    func addConstraints(in viewController: UIViewController) {
        translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(self)
        centerXAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -50).isActive = true
        centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor).isActive = true
    }
}
