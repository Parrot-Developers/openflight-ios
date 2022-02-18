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

/// Class used to provide a parent panel view controller which contains some properties.
open class AlertPanelViewController: UIViewController {
    public weak var delegate: HUDAlertPanelDelegate?
}

/// Manager which handles alert panel view controller.
public final class HUDAlertPanelProvider {
    // MARK: - Public Properties
    public static let shared: HUDAlertPanelProvider = HUDAlertPanelProvider()
    public private(set) var alertPanelViewControllers: HUDAlertViewControllers?

    // MARK: - Init
    private init() { }

    // MARK: - Public Funcs
    /// Setup custom alert view controller.
    ///
    /// - Parameters:
    ///     - alertPanelViewControllers: Custom view controllers for alert
    public func setupViewController(alertPanelViewControllers: HUDAlertViewControllers) {
        self.alertPanelViewControllers = alertPanelViewControllers
    }
}

// MARK: - Structs
/// Struct which stores each alert view controller.
public struct HUDAlertViewControllers {
    /// Provides a custom left panel view controller for alert.
    public var alertPanelViewController: () -> AlertPanelViewController

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - alertPanelViewController: The custom view controller for alert panel
    public init(alertPanelViewController: @escaping () -> AlertPanelViewController) {
        self.alertPanelViewController = alertPanelViewController
    }
}
