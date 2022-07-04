//    Copyright (C) 2022 Parrot Drones SAS
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

/// A banner alerts manager view model class.
class BannerAlertsManagerViewModel {
    /// The banner alerts display mode.
    @Published private(set) var mode: BannerAlertMode = .hidden
    /// The banner alerts stack.
    @Published private(set) var banners: [AnyBannerAlert] = []
    /// The banner alerts container frame.
    @Published private(set) var container: CGRect = UIScreen.main.bounds

    /// Combine cancellables.
    private var cancellables = Set<AnyCancellable>()

    /// Constructor.
    ///
    /// - Parameter service: the banner alert manager service
    init(service: BannerAlertManagerService) {
        service.bannersModePublisher.removeDuplicates()
            .combineLatest(service.bannersPublisher.removeDuplicates())
            .sink { [weak self] (mode, banners) in
                guard let self = self else { return }
                self.mode = mode
                self.banners = banners
            }
            .store(in: &cancellables)

        service.containerPublisher.removeDuplicates()
            .sink { [weak self] container in
                self?.container = container
            }
            .store(in: &cancellables)
    }
}
