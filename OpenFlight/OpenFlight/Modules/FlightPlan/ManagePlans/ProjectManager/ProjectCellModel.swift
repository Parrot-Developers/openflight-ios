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

import Foundation
import Pictor

/// A cell model describing a flights list table view row.
open class ProjectCellModel {

    /// The project name
    private(set) var title: String
    /// The last modification date
    private(set) var date: String?
    /// The project execution icon
    private(set) var isExecuted: Bool = false
    /// The project type
    private(set) var icon: UIImage?
    /// The project thumbnail
    private(set) var thumbnail: UIImage?
    /// Whether cell is selected.
    private(set) var isSelected: Bool = false

    // MARK: - Init
    /// Constructor.
    ///
    /// - Parameters:
    ///    - title: the project title
    ///    - date: the project date
    ///    - icon: the project type icon
    ///    - thumbnail: the project thumbnail
    ///    - isExecuted: the project has executions
    ///    - isSelected: whether the cell is selected
    init(title: String,
         date: String?,
         isExecuted: Bool,
         icon: UIImage?,
         thumbnail: UIImage?,
         isSelected: Bool) {
        self.title = title
        self.date = date
        self.isExecuted = isExecuted
        self.icon = icon
        self.thumbnail = thumbnail
        self.isSelected = isSelected
    }
}
