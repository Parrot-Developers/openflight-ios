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

import SwiftUI

struct MetricLogsListView: View {
    /// The MetricKit Sevice.
    var metricKitService: MetricKitService
    /// The log file urls.
    @State private var logUrls = [URL]()

    /// The View's body.
    var body: some View {
        List {
            ForEach(logUrls, id: \.self) { url in
                MetricLogsListCellView(metricKitService: metricKitService, url: url)
            }
            // Handle swipe deletion (iOS < 15)
            .onDelete(perform: deleteItems)
         }
        // Update logg list when a change is published.
        .onReceive(metricKitService.logUrlsPublisher) {
            logUrls = $0
        }
    }

    /// Delete list items.
    ///
    /// - Parameter offsets: the offsets index set of items to delete
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            metricKitService.deleteLogs(at: offsets.map { metricKitService.logUrls[$0] })
        }
    }
}

// MARK: - Preview
struct MetricLogsListView_Previews: PreviewProvider {
    static var previews: some View {
        MetricLogsListView(metricKitService: Services.hub.systemServices.metricKitService)
    }
}
