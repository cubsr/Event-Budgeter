//
//  DashboardView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var events: [Event]
    @Query private var people: [Person]

    private let currentYear = Calendar.current.component(.year, from: .now)

    private var upcomingEvents: [(event: Event, daysUntil: Int, assignments: [EventPerson])] {
        let today = Calendar.current.startOfDay(for: .now)
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 90, to: today) else { return [] }

        return events.compactMap { event -> (Event, Int, [EventPerson])? in
            guard let next = event.nextOccurrence, next >= today, next <= cutoff else { return nil }
            let days = Calendar.current.dateComponents([.day], from: today, to: next).day ?? 0
            return (event, days, event.assignments)
        }
        .sorted { $0.1 < $1.1 }
    }

    private var yearTotal: (spent: Decimal, budget: Decimal) {
        let cal = Calendar.current
        let allEventPersons = events.flatMap { $0.assignments }
        let spent = allEventPersons.flatMap { $0.purchases }
            .filter { cal.component(.year, from: $0.purchaseDate) == currentYear }
            .reduce(Decimal(0)) { $0 + $1.cost }
        let budget = allEventPersons.reduce(Decimal(0)) { $0 + $1.budget }
        return (spent, budget)
    }

    private var peopleBySpend: [(Person, Decimal)] {
        people
            .map { ($0, $0.totalSpent(inYear: currentYear)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        yearSummaryCard
                        upcomingSection
                        if !peopleBySpend.isEmpty {
                            peopleSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dashboard")
        }
    }

    private var yearSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(String(currentYear)) Overview")
                .sectionHeaderStyle()

            HStack(alignment: .firstTextBaseline) {
                Text(yearTotal.spent.currencyFormatted)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text("spent")
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                if yearTotal.budget > 0 {
                    Text("of \(yearTotal.budget.currencyFormatted)")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.subheadline)
                }
            }

            if yearTotal.budget > 0 {
                BudgetProgressBar(spent: yearTotal.spent, budget: yearTotal.budget, currency: "$")
            }
        }
        .bubbleCard()
    }

    @ViewBuilder
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming Up (next 90 days)")
                .sectionHeaderStyle()

            if upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.largeTitle)
                        .foregroundStyle(AppColors.accentMid)
                    Text("No events in the next 90 days")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ForEach(upcomingEvents, id: \.event.persistentModelID) { item in
                    DashboardEventCard(event: item.event, daysUntil: item.daysUntil)
                }
            }
        }
        .bubbleCard()
    }

    @ViewBuilder
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Person (\(String(currentYear)))")
                .sectionHeaderStyle()

            ForEach(peopleBySpend, id: \.0.persistentModelID) { person, spent in
                HStack {
                    PersonAvatarView(person: person, size: 32)
                    Text(person.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(spent.currencyFormatted)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.vertical, 4)
            }
        }
        .bubbleCard()
    }
}

private struct DashboardEventCard: View {
    let event: Event
    let daysUntil: Int

    private var totalSpent: Decimal { event.totalSpent }
    private var totalBudget: Decimal { event.totalBudget }
    private var progress: Double {
        guard totalBudget > 0 else { return 0 }
        return min(Double(truncating: (totalSpent / totalBudget) as NSDecimalNumber), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.displayEmoji)
                    .font(.title3)
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                DaysUntilBadge(days: daysUntil)
            }

            HStack {
                Text(totalSpent.currencyFormatted)
                    .fontWeight(.medium)
                    .foregroundStyle(totalSpent > totalBudget && totalBudget > 0 ? AppColors.barRed : .primary)
                if totalBudget > 0 {
                    Text("of \(totalBudget.currencyFormatted)")
                        .foregroundStyle(AppColors.textSecondary)
                        .font(.subheadline)
                }
                Spacer()
                if !event.assignments.isEmpty {
                    Text("\(event.assignments.count) \(event.assignments.count == 1 ? "person" : "people")")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if totalBudget > 0 {
                BudgetProgressBar(spent: totalSpent, budget: totalBudget, currency: "$")
            }
        }
        .padding(12)
        .background(AppColors.appBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
