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

import GroundSdk

/// Utility extension for `Camera2WhiteBalanceTemperature`.
extension Camera2WhiteBalanceTemperature: BarItemSubMode, RulerDisplayable, Sortable {
    // MARK: - BarItemMode
    public var title: String {
        return description
    }

    public var image: UIImage? {
        return nil
    }

    public var key: String {
        return description
    }

    public static var allValues: [BarItemMode] {
        let allTemperatures: [Camera2WhiteBalanceTemperature] = [.k2000, .k2250, .k2500, .k2750,
                                                                .k3000, .k3250, .k3500, .k3750,
                                                                .k4000, .k4250, .k4500, .k4750,
                                                                .k5000, .k5250, .k5500, .k5750,
                                                                .k6000, .k6250, .k6500, .k6750,
                                                                .k7000, .k7250, .k7500, .k7750,
                                                                .k8000, .k8250, .k8500, .k8750,
                                                                .k9000, .k9250, .k9500, .k9750,
                                                                .k10000]
        return allTemperatures
    }

    public var subModes: [BarItemSubMode]? {
        return nil
    }

    public var shutterText: String? {
        return nil
    }

    /// Alternative title with unit displayed.
    var altTitle: String {
        return String(format: "%@ %@", title, L10n.unitKelvin)
    }

    // MARK: - RulerDisplayable
    var rulerText: String? {
        switch self {
        case .k2000, .k3000, .k4000,
             .k5000, .k6000, .k7000,
             .k8000, .k9000, .k10000:
            return title
        default:
            return Style.pipe
        }
    }

    var rulerBackgroundColor: UIColor? {
        return nil
    }

    // MARK: - Sortable
    public static var sortedCases: [Camera2WhiteBalanceTemperature] {
        return [.k1500, .k1750, .k2000, .k2250, .k2500, .k2750, .k3000, .k3250, .k3500, .k3750, .k4000,
                .k4250, .k4500, .k4750, .k5000, .k5250, .k5500, .k5750, .k6000, .k6250, .k6500, .k6750,
                .k7000, .k7250, .k7500, .k7750, .k8000, .k8250, .k8500, .k8750, .k9000, .k9250, .k9500,
                .k9750, .k10000, .k10250, .k10500, .k10750, .k11000, .k11250, .k11500, .k11750, .k12000,
                .k12250, .k12500, .k12750, .k13000, .k13250, .k13500, .k13750, .k14000, .k14250, .k14500,
                .k14750, .k15000]
    }

    public var logKey: String {
        return LogEvent.LogKeyHUDBottomBarButton.whiteBalanceSetting.name
    }
}
