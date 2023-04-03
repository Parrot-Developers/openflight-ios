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

// /!\ Quick code: Debug purpose only.

import SwiftUI
import SwiftyUserDefaults

struct MetricLogsView: View {
    /// Dedicated to dismiss the view.
    @Environment(\.dismiss) var dismiss
    /// The MetricKit service.
    let metricKitService = Services.hub.systemServices.metricKitService
    /// Whether the Metric logging is enabled.
    @State private var isLoggingEnabled: Bool = Defaults.isMetricKitEnabled

    /// The View's body.
    var body: some View {
        // Main Stack.
        VStack {
            // Top Bar.
            MetricLogsTopBarView(metricKitService: metricKitService)
            Spacer()

            Form {
                // Metric Logging switch.
                Section {
                    Toggle("Enable Metric logging", isOn: $isLoggingEnabled)
                        .onChange(of: isLoggingEnabled) { enableLogging($0) }
                }
                // Logs list.
                Section {
                    MetricLogsListView(metricKitService: metricKitService)
                }
            }
         }
    }

    /// Sets Metric Logging state.
    ///
    /// - Parameter isEnabled: whether Metric logging is enabled
    private func enableLogging(_ isEnabled: Bool) {
        Defaults.isMetricKitEnabled = isEnabled
        if isEnabled {
            metricKitService.startLogging()
        } else {
            metricKitService.stopLogging()
        }
    }
}

// MARK: - Handling UIKit
class MetricLogsHostingController: UIHostingController<MetricLogsView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MetricLogsView())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - Preview
struct MetricLogsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricLogsView()
    }
}
