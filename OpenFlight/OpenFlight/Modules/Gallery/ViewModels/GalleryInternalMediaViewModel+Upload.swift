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

import GroundSdk

extension GalleryInternalMediaViewModel {
    /// Uploads media resources from a device URLs array to drone's internal memory.
    ///
    /// - Parameters:
    ///    - urls: URLs array of the media resources to upload.
    ///    - media: Media item to update with the uploaded resources.
    ///    - completion: Completion block returning upload task status and progress.
    func uploadResources(urls: [URL],
                         media: MediaItemCore,
                         completion: @escaping (MediaTaskStatus, Float) -> Void) {
        guard let mediaStore = mediaStore else { return }

        uploadRequest = mediaStore.newUploader(resources: urls, target: media) { uploader in
            guard let uploader = uploader else { return }
            completion(uploader.status, uploader.totalProgress)
        }
    }

    /// Cancel uploads.
    func cancelUploads(_ completion: (() -> Void)? = nil) {
        uploadRequest = nil
        drone?.getPeripheral(Peripherals.streamServer)?.enabled = true
        refreshMedias()
    }
}
