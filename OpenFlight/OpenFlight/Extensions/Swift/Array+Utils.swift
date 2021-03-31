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

/// Utility extension for `Array`.
extension Array {
    /// Returns element at given index, nil if out of bounds.
    ///
    /// - Parameters:
    ///    - index: index of the element
    /// - Returns: element at index, nil if out of bounds
    func elementAt(index: Int) -> Element? {
        guard !isEmpty,
              (0...self.count - 1).contains(index) else {
            return nil
        }

        return self[index]
    }
}

/// Utility extension for `Array` where elements are Hashable type.
extension Array where Element: Hashable {
    /// Returns current array with duplicates removed.
    var uniques: [Element] {
        return Array(Set(self))
    }
}

/// Utility extension for `Array` where elements are Int.
public extension Array where Element == Int {
    /// Filters array with a step.
    ///
    /// - Parameters:
    ///     - step: step used for filtering
    /// - Returns: Array of Element filtered with the step parameter.
    func stepFiltered(with step: Element) -> [Element] {
        return self.filter { $0 % step == 0 }
    }
}

/// Utility extension for `Array`.
extension Array {
    /// Returns true if an element T is in the current Array.
    ///
    /// - Parameters:
    ///     - element: array element to compare
    public func contains<T>(_ element: T) -> Bool where T: Equatable {
        return !self.filter({$0 as? T == element}).isEmpty
    }
}
