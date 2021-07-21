// Copyright (C) 2020 Parrot Drones SAS
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

/// Share file with the UIActivity ViewController.
protocol FileShare: AnyObject {
    /// Temporary shared file url.
    var temporaryShareUrl: URL? { get set }
    /// Share file.
    ///
    /// - Parameters:
    ///     - data: data to share
    ///     - name: file name
    ///     - fileExtension: file extension
    func shareFile(data: Data?, name: String?, fileExtension: String)
    /// Clean temporary file. Must be call on deinit, not before.
    func cleanTemporaryFile()
}

/// UIViewController FileShare code.
extension FileShare where Self: UIViewController {
    func shareFile(data: Data?, name: String?, fileExtension: String) {
        // Prepare data in background thread.
        DispatchQueue.global(qos: .background).async { [weak self] in
            if self?.temporaryShareUrl != nil {
                // Clean previous temporary file.
                self?.cleanTemporaryFile()
            }
            guard let fileData = data,
                  let fileTitle = name else {
                return
            }

            // Create temporary file to share, to have a file name and its extention.
            let path: String = NSTemporaryDirectory()
            let url = URL(fileURLWithPath: path)
                .appendingPathComponent(fileTitle)
                .appendingPathExtension(fileExtension)
            try? fileData.write(to: url)
            self?.temporaryShareUrl = url

            // Go back to main thread to display UIActivityViewController
            DispatchQueue.main.sync {
                // Show ActivityViewController.
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self?.view
                self?.present(activityViewController, animated: true, completion: {})
            }
        }
    }

    func cleanTemporaryFile() {
        if let url = temporaryShareUrl {
            // Remove temporary file to share if exists.
            try? FileManager.default.removeItem(at: url)
        }
    }
}
