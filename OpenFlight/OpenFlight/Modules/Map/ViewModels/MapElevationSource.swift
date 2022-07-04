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

import Combine
import ArcGIS
import GroundSdk

private extension ULogTag {
    static let tag = ULogTag(name: "MapElevationSource")
}

/// Data source for map elevation.
public class MapElevationSource: AGSArcGISTiledElevationSource {

    /// Whether elevation is loaded.
    @Published var elevationLoaded: Bool = false

    /// Whether elevation load failed and should be retried.
    @Published private var retry = false

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Enums
    private enum MapConstants {
        static let elevationURL = "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"
    }

    /// Constructor.
    ///
    /// - Parameters:
    ///    - networkService: network reachability service
    init(networkService: NetworkService) {
        guard let elevationUrl = URL(string: MapConstants.elevationURL) else {
            fatalError("Invalid URL")
        }

        super.init(url: elevationUrl)

        // retry load of elevation data when network is reachable
        networkService.networkReachable
            .combineLatest($retry)
            .filter { $0.0 && $0.1 }
            .sink { [weak self] _ in
                guard let self = self else { return }
                ULog.i(.tag, "Retry load")
                self.retry = false
                self.retryLoad()
            }.store(in: &cancellables)
    }

    /// Never call this method directly. The ArcGIS framework calls this method on a background thread.
    public override func onLoadStatusChanged() {
        super.onLoadStatusChanged()
        ULog.i(.tag, "Load status changed \(loadStatus)")
        elevationLoaded = loadStatus == .loaded
        retry = loadStatus == .failedToLoad
    }
}

/// Extension for debug description.
extension AGSLoadStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notLoaded: return "notLoaded"
        case .loading: return "loading"
        case .loaded: return "loaded"
        case .failedToLoad: return "failedToLoad"
        default: return "unknown"
        }
    }
}
