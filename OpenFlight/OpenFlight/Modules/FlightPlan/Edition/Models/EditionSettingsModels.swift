//
//  Copyright (C) 2020 Parrot Drones SAS.
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

// MARK: - Protocols
/// Protocol describing setting cell model.
protocol EditionSettingsCellModel {
    /// Delegate used in edition settings cell.
    var delegate: EditionSettingsCellModelDelegate? { get set }

    /// Sets up the view with the corresponding setting.
    ///
    /// - Parameters:
    ///     - settingType: current flight plan setting
    func fill(with settingType: FlightPlanSettingType?)

    /// Disables the cell by adding a view in front of the other element.
    ///
    /// - Parameters:
    ///     - mustDisable: specify if we must disable the cell or not
    func disableCell(_ mustDisable: Bool)

    /// Updates the trailing constraint of the cell.
    ///
    /// - Parameters:
    ///     - width: witdh of the trailing constraint
    func updateTrailingConstraint(_ width: CGFloat)
}

/// Protocol describing setting cell delegate.
public protocol EditionSettingsCellModelDelegate: class {
    /// Updates current settings value.
    ///
    /// - Parameters:
    ///     - key: current key for setting
    ///     - value: new value for setting
    func updateSettingValue(for key: String?, value: Int)

    /// Updates current settings choice.
    ///
    /// - Parameters:
    ///     - key: current key for setting
    ///     - value: current value for setting
    func updateChoiceSetting(for key: String?, value: Bool)
}
