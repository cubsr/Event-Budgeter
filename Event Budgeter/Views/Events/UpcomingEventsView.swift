//
//  UpcomingEventsView.swift
//  Event Budgeter
//
//  Redesigned "Upcoming" tab — bubble card design with filter chips.
//

import SwiftUI
import SwiftData

struct UpcomingEventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var events: [Event]

    var onDeleted: (() -> Void)? = nil

    @State private var filter: UpcomingFilter = .all

    enum UpcomingFilter: String, CaseIterable {
        case all = "All"
        case thirtyDays = "30 days"
        case ninetyDays = "90 days"
    }

    private var filteredEvents: [Event] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return events
            .compactMap { event -> (Event, Date, Int)? in
                guard let next = event.nextOccurrence else { return nil }
                let days = cal.dateComponents([.day], from: today, to: cal.startOfDay(for: next)).day ?? 0
                switch filter {
                case .all:
                    guard days >= -365 else { return nil }
                case .thirtyDays:
                    guard days >= 0 && days <= 30 else { return nil }
                case .ninetyDays:
                    guard days >= 0 && days <= 90 else { return nil }
                }
                return (event, next, days)
            }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }

    // Group by month
    private var grouped: [(String, [Event])] {
        let cal = Calendar.current
        var groups: [(String, [Event])] = []
        var seen: Set<String> = []
        for event in filteredEvents {
            guard let next = event.nextOccurrence else { continue }
            let comps = cal.dateComponents([.year, .month], from: next)
            guard let y = comps.year, let m = comps.month else { continue }
            let key = "\(y)-\(m)"
            let label = next.formatted(.dateTime.month(.wide).year())
            if !seen.contains(key) {
                seen.insert(key)
                groups.append((label, []))
            }
            let idx = groups.lastIndex { $0.0 == label }!
            groups[idx].1.append(event)
        }
        return groups
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(UpcomingFilter.allCases, id: \.self) { f in
                        FilterChip(label: f.rawValue, isActive: filter == f) {
                            filter = f
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)

            if events.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.accentMid)
                    Text("No events yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Add birthdays, holidays, and\nanniversaries to get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: []) {
                        ForEach(grouped, id: \.0) { label, items in
                            HStack {
                                Text(label)
                                    .sectionHeaderStyle()
                                    .padding(.leading, 20)
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                Spacer()
                            }

                            ForEach(items) { event in
                                NavigationLink {
                                    EventDetailView(event: event, onDeleted: onDeleted)
                                } label: {
                                    UpcomingEventCard(event: event)
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }
            }
        }
    }
}

// MARK: - Upcoming Event Card

struct UpcomingEventCard: View {
    let event: Event

    private var daysUntil: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let next = event.nextOccurrence else { return 0 }
        return cal.dateComponents([.day], from: today, to: cal.startOfDay(for: next)).day ?? 0
    }

    private var isPast: Bool { daysUntil < 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Event icon bubble
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(hex: event.category.color).opacity(0.15))
                        .frame(width: 46, height: 46)
                    Text(event.displayEmoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(event.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        DaysUntilBadge(days: daysUntil)
                    }

                    if let next = event.nextOccurrence {
                        HStack(spacing: 4) {
                            Text(next.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)

                            if !event.assignments.isEmpty {
                                Text("·")
                                    .foregroundStyle(AppColors.textTertiary)
                                Text(event.assignments.compactMap { $0.person?.name }.joined(separator: ", "))
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }

            // Budget bar
            if event.displayBudget > 0 || event.totalSpent > 0 {
                BudgetProgressBar(
                    spent: event.totalSpent,
                    budget: event.displayBudget,
                    currency: "$"
                )
            }

            if !event.notes.isEmpty {
                Text("\"\(event.notes)\"")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
                    .italic()
            }
        }
        .bubbleCard()
        .opacity(isPast ? 0.65 : 1)
    }
}
