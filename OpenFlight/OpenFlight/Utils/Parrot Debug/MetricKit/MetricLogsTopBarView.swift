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

struct MetricLogsTopBarView: View {
    /// Dedicated to dismiss the view.
    @Environment(\.dismiss) private var dismiss
    /// The MetricKit Sevice.
    var metricKitService: MetricKitService
    /// Whether there is some log files to delete.
    @State private var isLogsDirectoryEmpty: Bool = true
    /// Whether the delete confirmation dialog is presented.
    @State private var isPresentingConfirm: Bool = false

    /// The View's body.
    var body: some View {
        // Main Stack.
        HStack {
            // Back button.
            Button { dismiss() } label: {
                Label("Back", systemImage: "chevron.backward")
            }

            Spacer()

            // Title.
            Text("Metric Logs")
                .font(.title)

            Spacer()

            // Delete All Logs button.
            // /!\ Confirmation dialog is only supported starting iOS 15.
            // Earlier versions will delete logs immediately.
            if #available(iOS 15.0, *) {
                // MARK: iOS 15 and higher.
                Button("Delete all logs") {
                    isPresentingConfirm.toggle()
                }
                .foregroundColor(isLogsDirectoryEmpty ? .gray : .red)
                .disabled(isLogsDirectoryEmpty)
                .confirmationDialog("Are you sure?",
                                    isPresented: $isPresentingConfirm) {
                    Button("Delete all logs?", role: .destructive) {
                        metricKitService.clearLogs()
                    }
                } message: { Text("This action can't be undone") }
            } else {
                // MARK: < iOS 15.
                Button("Delete all logs") {
                    metricKitService.clearLogs()
                }
                .foregroundColor(isLogsDirectoryEmpty ? .gray : .red)
                .disabled(isLogsDirectoryEmpty)
            }
        }
        .padding(.top, 5)
        // Update delete button when log list change.
        .onReceive(metricKitService.logUrlsPublisher) {
            isLogsDirectoryEmpty = $0.isEmpty
        }
    }

}

// MARK: - Preview
struct MetricLogsTopBarView_Previews: PreviewProvider {
    static var previews: some View {
        MetricLogsTopBarView(metricKitService: Services.hub.systemServices.metricKitService)
    }
}
