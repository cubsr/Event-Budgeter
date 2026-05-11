//
//  CalendarTabView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct CalendarTabView: View {
    @Query private var events: [Event]
    @Environment(\.modelContext) private var modelContext

    @State private var displayedMonth: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate: Date? = nil

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide))
    }
    private var yearTitle: String {
        displayedMonth.formatted(.dateTime.year())
    }

    private var eventsForSelected: [Event] {
        guard let selected = selectedDate else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: selected)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return [] }
        return events.filter { !$0.occurrences(in: start..<end).isEmpty }
    }

    private var monthRange: Range<Date> {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: displayedMonth) else {
            return Date.now..<Date.now
        }
        return interval.start..<interval.end
    }

    private var monthSummary: (count: Int, budget: Decimal, spent: Decimal) {
        let monthEvts = events.filter { !$0.occurrences(in: monthRange).isEmpty }
        let budget = monthEvts.reduce(Decimal(0)) { $0 + $1.displayBudget }
        let spent  = monthEvts.reduce(Decimal(0)) { $0 + $1.totalSpent }
        return (monthEvts.count, budget, spent)
    }

    private var sortedMonthEvents: [Event] {
        events
            .filter { !$0.occurrences(in: monthRange).isEmpty }
            .sorted { a, b in
                let aDate = a.occurrences(in: monthRange).first ?? .distantFuture
                let bDate = b.occurrences(in: monthRange).first ?? .distantFuture
                return aDate < bDate
            }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Month nav header
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                            selectedDate = nil
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.accentText)
                            .frame(width: 34, height: 34)
                            .background(AppColors.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    Spacer()

                    VStack(spacing: 1) {
                        Text(monthTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(yearTitle)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                            selectedDate = nil
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.accentText)
                            .frame(width: 34, height: 34)
                            .background(AppColors.accentSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                // Calendar grid
                CalendarGridView(
                    displayedMonth: displayedMonth,
                    events: events,
                    selectedDate: $selectedDate
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

                // Month budget summary strip
                HStack(spacing: 0) {
                    ForEach([
                        ("Events",   "\(monthSummary.count)"),
                        ("Budgeted", "$\(NSDecimalNumber(decimal: monthSummary.budget).intValue)"),
                        ("Spent",    "$\(NSDecimalNumber(decimal: monthSummary.spent).intValue)"),
                    ], id: \.0) { label, value in
                        VStack(spacing: 2) {
                            Text(value)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(label)
                                .font(.system(size: 10))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)
                .background(AppColors.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

                // Selected day events
                if let selectedDate {
                    if eventsForSelected.isEmpty {
                        Text("No events on \(selectedDate.formatted(.dateTime.day().month()))")
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(eventsForSelected) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    CalendarEventCard(event: event)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                } else {
                    // Show all month events
                    if sortedMonthEvents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.accentMid)
                            Text("No events this month")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(sortedMonthEvents) { event in
                                NavigationLink {
                                    EventDetailView(event: event)
                                } label: {
                                    CalendarEventCard(event: event)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Color.clear.frame(height: 100)
            }
        }
    }
}

// MARK: - Calendar Event Card

private struct CalendarEventCard: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: event.category.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                Text(event.displayEmoji)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                if !event.assignments.isEmpty {
                    Text(event.assignments.compactMap { $0.person?.name }.joined(separator: ", "))
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if event.displayBudget > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(NSDecimalNumber(decimal: event.totalSpent).intValue)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(event.totalSpent > event.displayBudget ? AppColors.barRed : .primary)
                    Text("of $\(NSDecimalNumber(decimal: event.displayBudget).intValue)")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
        }
        .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
        .contentShape(Rectangle())
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
