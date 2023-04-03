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

struct MetricLogsListCellView: View {
    /// The MetricKit Sevice.
    let metricKitService: MetricKitService
    /// The Log Url.
    let url: URL

    /// The View's body.
    var body: some View {
        ZStack {
            // MARK: iOS 15 and higher.
            if #available(iOS 15.0, *) {
                Text(url.lastPathComponent)
                    .foregroundColor(url.filenameColor)
                    .swipeActions(allowsFullSwipe: false) {
                        // Share button.
                        Button {
                            UIApplication.export(url: url)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.indigo)

                        // Delete button.
                        Button(role: .destructive) {
                            metricKitService.deleteLogs(at: [url])
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
            } else {
                // MARK: < iOS 15.
                HStack {
                    Text(url.lastPathComponent)
                        .foregroundColor(url.filenameColor)
                    Spacer()
                    // Export button.
                    Button {
                        UIApplication.export(url: url)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    // Note: Item deletion is handled directly in the list using this cell.
                }
            }
        }
    }
}

// MARK: - Private extensions
private extension URL {
    /// The filename color according to its extension.
    var filenameColor: SwiftUI.Color {
        switch pathExtension {
        case "metric":
            return .blue
        case "diagnostic":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Preview
struct MetricLogsListCellView_Previews: PreviewProvider {
    static var previews: some View {
        MetricLogsListCellView(metricKitService: Services.hub.systemServices.metricKitService,
                               url: URL(string: "logs/Metric_2023-02-18-002958.metric")!)
    }
}
