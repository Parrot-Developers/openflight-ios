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

import GroundSdk

/// State for `GalleryMediaViewModel`.

class GalleryMediaState: GalleryMediaSourceState {

    /// All sorded medias list.
    private(set) var sortedMedias: [(key: Date, medias: [GalleryMedia])] = []
    /// Selected media type.
    fileprivate(set) var selectedMediaType: GalleryMediaType? {
        didSet {
            sortedMedias = sortItems()
        }
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        return super.isEqual(to: other)
    }

    override func copy() -> GalleryMediaState {
        return GalleryMediaState()
    }

    override func mediasWereUpdated() {
        sortedMedias = sortItems()
    }

}

// MARK: - Private Funcs
private extension GalleryMediaState {
    /// Sort items.
    ///
    /// - Returns: list of items ordered by date and possibly filtered by type.
    private func sortItems() -> [(key: Date, medias: [GalleryMedia])] {
        var sortedItems: [(key: Date, medias: [GalleryMedia])] = []
        var sortedData = medias.sorted(by: { $0.mediaItem.creationDate > $1.mediaItem.creationDate })
        if let type = selectedMediaType {
            sortedData = sortedData.filter({$0.type == type})
        }
        for item in sortedData {
            if let currentDate = sortedItems.first(where: { $0.key.isSameDay(date: item.date) }) {
                var newDateTuple = currentDate
                sortedItems.removeAll(where: { $0.key.isSameDay(date: currentDate.key) })
                newDateTuple.medias.append(item)
                sortedItems.append(newDateTuple)
            } else {
                sortedItems.append((key: item.date, medias: [item]))
            }
        }
        return sortedItems
    }
}
