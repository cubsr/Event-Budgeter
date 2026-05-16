//
//  Event+Recurrence.swift
//  Event Budgeter
//

import Foundation

extension Event {
    func occurrenceDate(inYear year: Int) -> Date? {
        let cal = Calendar.current
        switch recurrenceRule {
        case .none:
            return cal.component(.year, from: canonicalDate) == year ? canonicalDate : nil
        case .yearly:
            var comps = cal.dateComponents([.month, .day], from: canonicalDate)
            comps.year = year
            return cal.date(from: comps)
        case .nthWeekdayYearly:
            guard let nth = recurrenceNth, let weekday = recurrenceWeekday,
                  let month = cal.dateComponents([.month], from: canonicalDate).month
            else { return nil }
            return cal.nthWeekday(nth, weekday: weekday, month: month, year: year)
        }
    }

    func occurrences(in range: Range<Date>) -> [Date] {
        let cal = Calendar.current
        let startYear = cal.component(.year, from: range.lowerBound)
        let endYear = cal.component(.year, from: range.upperBound)
        return (startYear...endYear).compactMap { occurrenceDate(inYear: $0) }.filter { range.contains($0) }
    }

    var nextOccurrence: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let thisYear = cal.component(.year, from: today)
        for year in thisYear...(thisYear + 1) {
            if let date = occurrenceDate(inYear: year), date >= today {
                return date
            }
        }
        return nil
    }

    var daysUntilNext: Int? {
        guard let next = nextOccurrence else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: next).day
    }

    var nextOccurrenceFormatted: String {
        guard let next = nextOccurrence else { return "One time" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: next)
    }
}

extension Calendar {
    /// Returns the date of the nth occurrence of `weekday` in `month`/`year`.
    /// weekday uses Calendar convention: 1=Sunday … 7=Saturday.
    /// nth: 1=first, 2=second, 3=third, 4=fourth, -1=last.
    func nthWeekday(_ nth: Int, weekday: Int, month: Int, year: Int) -> Date? {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.weekday = weekday
        comps.weekdayOrdinal = nth
        return self.date(from: comps)
    }
}
