//
//  HolidaySeeder.swift
//  Event Budgeter
//

import Foundation
import SwiftData

struct HolidaySeeder {

    private struct Template {
        let systemKey: String
        let title: String
        let emoji: String
        // nth-weekday holidays
        let nth: Int?
        let weekday: Int?   // Calendar weekday: 1=Sun … 7=Sat
        let month: Int?
        // Fixed-date holidays
        let fixedMonth: Int?
        let fixedDay: Int?
    }

    private static let templates: [Template] = [
        // Nth-weekday (dynamic each year)
        Template(systemKey: "holiday.mothers_day",  title: "Mother's Day",   emoji: "🌸", nth: 2,  weekday: 1, month: 5,  fixedMonth: nil, fixedDay: nil),
        Template(systemKey: "holiday.fathers_day",  title: "Father's Day",   emoji: "👔", nth: 3,  weekday: 1, month: 6,  fixedMonth: nil, fixedDay: nil),
        Template(systemKey: "holiday.thanksgiving", title: "Thanksgiving",   emoji: "🦃", nth: 4,  weekday: 5, month: 11, fixedMonth: nil, fixedDay: nil),
        // Fixed date (same day every year)
        Template(systemKey: "holiday.christmas",    title: "Christmas",      emoji: "🎄", nth: nil, weekday: nil, month: nil, fixedMonth: 12, fixedDay: 25),
        Template(systemKey: "holiday.halloween",    title: "Halloween",      emoji: "🎃", nth: nil, weekday: nil, month: nil, fixedMonth: 10, fixedDay: 31),
        Template(systemKey: "holiday.valentines",   title: "Valentine's Day",emoji: "❤️", nth: nil, weekday: nil, month: nil, fixedMonth: 2,  fixedDay: 14),
        Template(systemKey: "holiday.new_years",    title: "New Year's Day", emoji: "🎊", nth: nil, weekday: nil, month: nil, fixedMonth: 1,  fixedDay: 1),
    ]

    /// Inserts any default holidays not yet present in the store.
    /// Idempotent — safe to call every launch. Uses systemKey to detect existing holidays,
    /// so it survives user renames and handles partially-seeded states gracefully.
    static func seedIfNeeded(context: ModelContext, existingEvents: [Event]) {
        let existingKeys = Set(existingEvents.compactMap(\.systemKey))
        let cal = Calendar.current
        let currentYear = cal.component(.year, from: .now)

        for template in templates {
            guard !existingKeys.contains(template.systemKey) else { continue }

            let canonicalDate: Date
            let rule: RecurrenceRule
            let nth: Int?
            let weekday: Int?

            if let n = template.nth, let wd = template.weekday, let mo = template.month {
                guard let date = cal.nthWeekday(n, weekday: wd, month: mo, year: currentYear) else { continue }
                canonicalDate = date
                rule = .nthWeekdayYearly
                nth = n
                weekday = wd
            } else if let fm = template.fixedMonth, let fd = template.fixedDay {
                var comps = DateComponents()
                comps.year = currentYear
                comps.month = fm
                comps.day = fd
                guard let date = cal.date(from: comps) else { continue }
                canonicalDate = date
                rule = .yearly
                nth = nil
                weekday = nil
            } else {
                continue
            }

            let event = Event(
                title: template.title,
                emoji: template.emoji,
                category: .holiday,
                canonicalDate: canonicalDate,
                recurrenceRule: rule,
                recurrenceNth: nth,
                recurrenceWeekday: weekday,
                systemKey: template.systemKey
            )
            context.insert(event)
        }
    }
}
