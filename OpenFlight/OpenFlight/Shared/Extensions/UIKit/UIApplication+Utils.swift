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

/// Utility extension for `UIApplication`.

public extension UIApplication {
    /// Check orientation mode.
    ///
    /// - Returns: True if we are in Landscape mode.
    static var isLandscape: Bool {
        switch UIApplication.shared.statusBarOrientation {
        case .portrait, .portraitUpsideDown:
            return false
        default:
            return true
        }
    }

    static var window: UIWindow? {
        shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }

    /// Gets the current top view controller
    ///
    /// - Parameters:
    ///     - viewController: The view controller to check
    /// - Returns: The top view controller
    class func topViewController(_ viewController: UIViewController? = window?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        return viewController
    }

    /// Displays an activity view controller allowing to export files with their URLs.
    ///
    /// - Parameters:
    ///    - urls: the file urls to export
    ///    - applicationActivities: the available applications activities filters
    class func export(urls: [URL], applicationActivities: [UIActivity]? = nil) {
        // Ensure top view controller is accessible.
        guard let topViewController = UIApplication.topViewController()
        else { return }

        let activityVC = UIActivityViewController(activityItems: urls,
                                                  applicationActivities: applicationActivities)
        // Handle popover dispay.
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = topViewController.view
            popoverController.sourceRect = topViewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        topViewController.present(activityVC, animated: true, completion: nil)
    }

    /// Displays an activity view controller allowing to export a file with its URL.
    ///
    /// - Parameters:
    ///    - url: the file url to export
    ///    - applicationActivities: the available applications activities filters
    class func export(url: URL, applicationActivities: [UIActivity]? = nil) {
        export(urls: [url], applicationActivities: applicationActivities)
    }
}
