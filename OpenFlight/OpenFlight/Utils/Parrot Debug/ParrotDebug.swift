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

import SwiftyUserDefaults
import GroundSdk

/// Class to manage debug logs.
public class ParrotDebug {
    // MARK: - Public Properties
    static let debugTag = ULogTag(name: "ParrotDebug")
    static var activeLogFileName: String?
    static let streamDbgPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        as NSString).appendingPathComponent("stream")
}

// MARK: - Public Funcs
public extension ParrotDebug {
    /// Start smart log.
    static func smartStartLog() {
        if !Defaults.hasKey(\.activatedLog) {
            // Use the default configuration.
            #if DEBUG
            startLog()
            #else
            if Bundle.main.isInHouseBuild {
                startLog()
            }
            #endif
        } else {
            if Defaults.activatedLog == true {
                startLog()
            }
        }
    }

    /// Starts Log.
    static func startLog() {
        guard activeLogFileName == nil else {
            return
        }
        setenv("ULOG_LEVEL", "D", 1)
        activeLogFileName = ULog.startFileRecord()
        setStreamDbgEnv()
    }

    /// Stops Log.
    static func stopLog() {
        guard activeLogFileName != nil else {
            return
        }
        ULog.stopFileRecord()
        self.activeLogFileName = nil
    }

    /// Creates a stream debug path.
    static func createStreamDebugPath() {
        if !streamDebugPathExists() {
            try? FileManager.default.createDirectory(atPath: streamDbgPath,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
    }

    /// Returns true if stream debug path exists.
    static func streamDebugPathExists() -> Bool {
        return FileManager.default.fileExists(atPath: streamDbgPath)
    }

    /// Returns a list of files containing logs.
    static func listLogFiles() -> [URL] {
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(
                at: logsURL, includingPropertiesForKeys: nil, options: [])
            return directoryContents
        } catch {
            ULog.e(debugTag, "listLogFiles - Error \(error)")
            return []
        }
    }

    /// Remove a log file.
    ///
    /// - Parameters:
    ///     - fileUrl: url of the file
    ///     - completionOK: callback called when file is deleted
    static func removeLogUrl(fileURL: URL, srcVC: UIViewController, completionOK: @escaping () -> Void) {
        let alertController = UIAlertController(title: L10n.commonConfirmation, message: L10n.debugLogConfirmDelete, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: L10n.commonDelete, style: .destructive, handler: { _ in
            do {
                try FileManager.default.removeItem(at: fileURL)
                completionOK()
            } catch {
                ULog.e(debugTag, "Failed to delete file \(fileURL.lastPathComponent) - \(error)" )
            }
        }))
        alertController.addAction(UIAlertAction(title: L10n.cancel, style: .cancel, handler: nil))
        srcVC.present(alertController, animated: true, completion: nil)
    }

    /// Rename a log file.
    ///
    /// - Parameters:
    ///     - fileUrl: url of the file
    ///     - withLastComponent: last component
    static func renameLogFile(fromUrl: URL, withLastComponent: String) {
        var newUrl = fromUrl.deletingLastPathComponent()
        newUrl.appendPathComponent(withLastComponent, isDirectory: false)
        do {
            try FileManager.default.moveItem(at: fromUrl, to: newUrl)
        } catch {
            ULog.e(debugTag, "Rename from \(fromUrl) to \(newUrl) - Error \(error)")
        }
    }
}

// MARK: - Private Funcs
private extension ParrotDebug {
    /// Set new debug environnement for stream.
    static func setStreamDbgEnv() {
        if streamDebugPathExists() {
            setenv("VSTRM_DBG_DIR", streamDbgPath, 1)
            // Set VSTRM_DBG_FLAGS to the VSTRM_DBG_FLAG_RECEIVER_STREAM value according to the libvideo-streaming"
            setenv("VSTRM_DBG_FLAGS", "4", 1)
        }
    }

    /// Returns the log directory url.
    static var logsURL: URL = {
        return URL(fileURLWithPath: ULog.getPath())
    }()
}
