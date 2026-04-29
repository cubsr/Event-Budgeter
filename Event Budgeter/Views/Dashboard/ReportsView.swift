//
//  ReportsView.swift
//  Event Budgeter
//
//  Yearly reports: summary cards, monthly bar chart, by-person, by-category.
//

import SwiftUI
import SwiftData

struct ReportsView: View {
    @Query private var events: [Event]
    @Query(sort: \Person.name) private var people: [Person]

    private let currentYear = Calendar.current.component(.year, from: .now)
    @State private var selectedYear: Int

    init() {
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: .now))
    }

    private var yearEvents: [Event] {
        events.filter { event in
            guard let next = event.nextOccurrence else { return false }
            return Calendar.current.component(.year, from: event.canonicalDate) == selectedYear
                || Calendar.current.component(.year, from: next) == selectedYear
        }
    }

    private var totalBudget: Decimal { yearEvents.reduce(0) { $0 + $1.displayBudget } }
    private var totalSpent:  Decimal { yearEvents.reduce(0) { $0 + $1.totalSpent } }
    private var remaining:   Decimal { totalBudget - totalSpent }

    private let monthAbbrevs = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

    private var monthlyData: [(month: String, budget: Decimal, spent: Decimal)] {
        (0..<12).map { m in
            let cal = Calendar.current
            let mes = yearEvents.filter { event in
                guard let comps = cal.dateComponents([.year, .month], from: event.canonicalDate).month else { return false }
                return comps == m + 1
            }
            return (
                month: monthAbbrevs[m],
                budget: mes.reduce(0) { $0 + $1.displayBudget },
                spent:  mes.reduce(0) { $0 + $1.totalSpent }
            )
        }
    }

    private var maxMonthly: Decimal {
        monthlyData.map { $0.budget }.max() ?? 1
    }

    private var personSpending: [(Person, Int, Decimal, Decimal)] {
        people.map { p in
            let ps = yearEvents.filter { $0.assignments.contains { $0.person?.persistentModelID == p.persistentModelID } }
            let budget = ps.reduce(Decimal(0)) { sum, e in
                sum + (e.assignments.first { $0.person?.persistentModelID == p.persistentModelID }?.budget ?? 0)
            }
            let spent = ps.reduce(Decimal(0)) { sum, e in
                sum + (e.assignments.first { $0.person?.persistentModelID == p.persistentModelID }?.totalSpent ?? 0)
            }
            return (p, ps.count, spent, budget)
        }
        .filter { $0.3 > 0 }
        .sorted { $0.3 > $1.3 }
    }

    private var categorySpending: [(EventCategory, Int, Decimal, Decimal)] {
        EventCategory.allCases.compactMap { cat in
            let es = yearEvents.filter { $0.category == cat }
            guard !es.isEmpty else { return nil }
            let budget = es.reduce(Decimal(0)) { $0 + $1.displayBudget }
            let spent  = es.reduce(Decimal(0)) { $0 + $1.totalSpent }
            return (cat, es.count, spent, budget)
        }
        .sorted { $0.3 > $1.3 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header with year selector
                        HStack {
                            Text("Reports")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Spacer()

                            HStack(spacing: 6) {
                                ForEach([selectedYear - 1, selectedYear, selectedYear + 1], id: \.self) { year in
                                    Button {
                                        selectedYear = year
                                    } label: {
                                        Text(String(year))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(selectedYear == year ? .white : AppColors.accentText)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(selectedYear == year ? AppColors.accent : AppColors.accentSoft)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)

                        // Summary cards
                        HStack(spacing: 10) {
                            ForEach([
                                ("Budget", totalBudget,  AppColors.accent),
                                ("Spent",  totalSpent,   AppColors.barGreen),
                                ("Left",   remaining,    remaining >= 0 ? AppColors.barYellow : AppColors.barRed),
                            ], id: \.0) { label, value, color in
                                VStack(spacing: 4) {
                                    Text("$\(NSDecimalNumber(decimal: value).intValue)")
                                        .font(.system(size: 17, weight: .heavy))
                                        .foregroundStyle(color)
                                    Text(label)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .bubbleCard(padding: .init(top: 14, leading: 8, bottom: 14, trailing: 8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                        // Monthly bar chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Spend")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.primary)

                            MonthlyBarChart(data: monthlyData, maxValue: maxMonthly)
                                .frame(height: 100)

                            // Legend
                            HStack(spacing: 16) {
                                HStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(AppColors.accentSoft)
                                        .frame(width: 10, height: 10)
                                    Text("Budget")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                HStack(spacing: 5) {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(AppColors.accent)
                                        .frame(width: 10, height: 10)
                                    Text("Spent")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                        // By Person
                        if !personSpending.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("By Person")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)

                                ForEach(personSpending, id: \.0.persistentModelID) { person, count, spent, budget in
                                    HStack(spacing: 10) {
                                        PersonAvatarView(person: person, size: 32)

                                        VStack(spacing: 4) {
                                            HStack {
                                                Text(person.name)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                Spacer()
                                                Text("$\(NSDecimalNumber(decimal: spent).intValue)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppColors.textSecondary)
                                                + Text(" / $\(NSDecimalNumber(decimal: budget).intValue)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppColors.textTertiary)
                                            }

                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(AppColors.barBg)
                                                        .frame(height: 5)
                                                    Capsule()
                                                        .fill(Color(hex: person.colorHex))
                                                        .frame(
                                                            width: budget > 0
                                                                ? geo.size.width * min(NSDecimalNumber(decimal: spent / budget).doubleValue, 1.0)
                                                                : 0,
                                                            height: 5
                                                        )
                                                }
                                            }
                                            .frame(height: 5)
                                        }

                                        Text("\(count) ev")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppColors.textTertiary)
                                            .frame(minWidth: 30, alignment: .trailing)
                                    }
                                }
                            }
                            .bubbleCard()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }

                        // By Category
                        if !categorySpending.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("By Occasion")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)

                                ForEach(categorySpending, id: \.0) { cat, _, spent, budget in
                                    HStack(spacing: 10) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(Color(hex: cat.color).opacity(0.15))
                                                .frame(width: 32, height: 32)
                                            Text(cat.defaultEmoji)
                                                .font(.system(size: 16))
                                        }

                                        VStack(spacing: 4) {
                                            HStack {
                                                Text(cat.label)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                Spacer()
                                                Text("$\(NSDecimalNumber(decimal: spent).intValue) / $\(NSDecimalNumber(decimal: budget).intValue)")
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }

                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(AppColors.barBg)
                                                        .frame(height: 5)
                                                    Capsule()
                                                        .fill(Color(hex: cat.color))
                                                        .frame(
                                                            width: budget > 0
                                                                ? geo.size.width * min(NSDecimalNumber(decimal: spent / budget).doubleValue, 1.0)
                                                                : 0,
                                                            height: 5
                                                        )
                                                }
                                            }
                                            .frame(height: 5)
                                        }
                                    }
                                }
                            }
                            .bubbleCard()
                            .padding(.horizontal, 16)
                            .padding(.bottom, 14)
                        }

                        // People section with management link
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("People")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                NavigationLink {
                                    PeopleListView()
                                } label: {
                                    Text("Manage")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(AppColors.accentText)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(AppColors.accentSoft)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }

                            if people.isEmpty {
                                Text("No people added yet.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(people.prefix(5)) { person in
                                    NavigationLink {
                                        PersonDetailView(person: person)
                                    } label: {
                                        HStack(spacing: 12) {
                                            PersonAvatarView(person: person, size: 34)
                                            Text(person.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.primary)
                                            if !person.relationshipLabel.isEmpty {
                                                Text(person.relationshipLabel)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppColors.textTertiary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                if people.count > 5 {
                                    NavigationLink {
                                        PeopleListView()
                                    } label: {
                                        Text("View all \(people.count) people →")
                                            .font(.system(size: 13))
                                            .foregroundStyle(AppColors.accentText)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)

                        Color.clear.frame(height: 50)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Monthly Bar Chart

private struct MonthlyBarChart: View {
    let data: [(month: String, budget: Decimal, spent: Decimal)]
    let maxValue: Decimal

    @State private var hoveredIdx: Int? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(data.enumerated()), id: \.offset) { idx, item in
                VStack(spacing: 3) {
                    Spacer(minLength: 0)

                    // Bar
                    ZStack(alignment: .bottom) {
                        // Budget bar (background)
                        if item.budget > 0 {
                            let budgetH = CGFloat(NSDecimalNumber(decimal: item.budget / maxValue).doubleValue) * 72
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(AppColors.accentSoft)
                                .frame(height: max(budgetH, 4))

                            // Spent overlay
                            if item.spent > 0 {
                                let spentH = CGFloat(NSDecimalNumber(decimal: item.spent / maxValue).doubleValue) * 72
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(AppColors.accent.opacity(0.85))
                                    .frame(height: max(spentH, 4))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.4), value: maxValue)

                    // Month label
                    Text(item.month)
                        .font(.system(size: 8))
                        .foregroundStyle(AppColors.textTertiary)
                        .frame(height: 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
