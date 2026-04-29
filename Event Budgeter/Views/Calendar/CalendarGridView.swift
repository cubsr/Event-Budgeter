//
//  CalendarGridView.swift
//  Event Budgeter
//

import SwiftUI

struct CalendarGridView: View {
    let displayedMonth: Date
    let events: [Event]
    @Binding var selectedDate: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let dayHeaders = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    private var daysInGrid: [Date?] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = cal.dateInterval(of: .weekOfYear, for: monthInterval.start)
        else { return [] }

        var dates: [Date?] = []
        var current = firstWeek.start
        let end = monthInterval.end

        while current < end || dates.count % 7 != 0 {
            dates.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current)!
            if dates.count > 42 { break }
        }
        return dates
    }

    private func eventsFor(_ date: Date) -> [Event] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return events.filter { !$0.occurrences(in: start..<end).isEmpty }
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(dayHeaders, id: \.self) { header in
                    Text(header)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 4)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        let dayEvents = eventsFor(date)
                        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
                        CalendarDayCell(
                            date: date,
                            isCurrentMonth: isCurrentMonth(date),
                            isToday: Calendar.current.isDateInToday(date),
                            events: dayEvents,
                            isSelected: isSelected
                        )
                        .onTapGesture {
                            selectedDate = (isSelected ? nil : date)
                        }
                    }
                }
            }
        }
    }
}
