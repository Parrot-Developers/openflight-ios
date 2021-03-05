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

import Foundation

/// Utility extension for `Date`.

extension Date {
    /// Returns date's month as string.
    var month: String {
        return DateFormatter.month.string(from: self)
    }

    /// Returns date's year as string.
    var year: String {
        return DateFormatter.year.string(from: self)
    }

    /// Compares day component of self and now.
    var isToday: Bool { isEqual(to: Date(), toGranularity: .day) }

    /// Compares day component of self and yesterday.
    var isYesterday: Bool {
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            return isEqual(to: yesterday, toGranularity: .day)
        }
        return false
    }

    /// Compares two dates regarding calendar component.
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: date, toGranularity: component)
    }

    /// Compares month component of two dates.
    func isInSameMonth(date: Date) -> Bool { isEqual(to: date, toGranularity: .month) }

    /// Compares day of two dates.
    func isSameDay(date: Date, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: date)
    }

    /// Returns date's formatted string with given style.
    func formattedString(dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }

    /// Short formatted date.
    var shortFormattedString: String? {
        if self.isToday {
            return L10n.commonToday
        } else if self.isYesterday {
            return L10n.commonYesterday
        } else {
            return self.formattedString(dateStyle: .short, timeStyle: .medium)
        }
    }

    /// Short formatted date, always show time.
    var shortWithTimeFormattedString: String? {
        if self.isToday {
            return addTimeTo(stringDate: L10n.commonToday)
        } else if self.isYesterday {
            return addTimeTo(stringDate: L10n.commonYesterday)
        } else {
            return self.formattedString(dateStyle: .short, timeStyle: .medium)
        }
    }

    /// Add time to formatted date.
    ///
    /// - Parameters:
    /// - stringDate: date as string to add time
    private func addTimeTo(stringDate: String) -> String {
        return String(format: "%@ %@",
                      stringDate,
                      self.formattedString(dateStyle: .none,
                                           timeStyle: .short))
    }
}
