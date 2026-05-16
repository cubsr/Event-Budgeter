//
//  PersonDetailView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let person: Person
    var onDeleted: (() -> Void)? = nil
    var onSaved: (() -> Void)? = nil

    @State private var showingEdit = false
    @State private var selectedYear = Calendar.current.component(.year, from: .now)
    @State private var editingEventPerson: EventPerson?
    @State private var showingDeleteConfirm = false

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 3)...currentYear).reversed()
    }

    private var yearlyTotal: Decimal {
        person.totalSpent(inYear: selectedYear)
    }

    private var sortedAssignments: [EventPerson] {
        person.assignments.sorted { a, b in
            let aDate = a.event?.nextOccurrence ?? .distantFuture
            let bDate = b.event?.nextOccurrence ?? .distantFuture
            return aDate < bDate
        }
    }

    var body: some View {
        ZStack {
            AppColors.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    // Header card
                    HStack(spacing: 16) {
                        PersonAvatarView(person: person, size: 64)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(person.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            if !person.displayRelationshipLabel.isEmpty {
                                Text(person.displayRelationshipLabel)
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Text("All time: \(person.totalSpentAllTime.currencyFormatted)")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textTertiary)
                        }

                        Spacer()
                    }
                    .bubbleCard()
                    .padding(.horizontal, 16)

                    // Year selector + spend
                    VStack(spacing: 10) {
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Text("Spent in \(String(selectedYear))")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            Text(yearlyTotal.currencyFormatted)
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
                    .bubbleCard()
                    .padding(.horizontal, 16)

                    // Events section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Events & Gifts")
                            .sectionHeaderStyle()
                            .padding(.horizontal, 4)

                        if sortedAssignments.isEmpty {
                            Text("Not assigned to any events yet.")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .bubbleCard()
                        } else {
                            ForEach(sortedAssignments) { ep in
                                if let event = ep.event {
                                    NavigationLink {
                                        PurchaseListView(eventPerson: ep)
                                    } label: {
                                        PersonEventRow(ep: ep, event: event)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            editingEventPerson = ep
                                        } label: {
                                            Label("Budget", systemImage: "pencil")
                                        }
                                        .tint(AppColors.accent)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 14)
            }
        }
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Edit Person") { showingEdit = true }
                Divider()
                Button(person.isHidden ? "Unhide Person" : "Hide Person") {
                    person.isHidden.toggle()
                    if person.isHidden { dismiss() }
                }
                Divider()
                Button("Delete Person", role: .destructive) {
                    showingDeleteConfirm = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(AppColors.accent)
            }
        }
        .sheet(isPresented: $showingEdit) {
            AddEditPersonView(person: person, onSaved: onSaved)
        }
        .confirmationDialog(
            "Delete \(person.name)?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deletePerson()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes \(person.name) and any birthday event tied to them. Other events will keep their other people.")
        }
        .sheet(item: $editingEventPerson) { ep in
            EditEventPersonBudgetSheet(eventPerson: ep)
        }
    }

    private func deletePerson() {
        for ep in person.assignments {
            if let event = ep.event, event.category == .birthday {
                NotificationManager.cancelNotification(for: event)
                modelContext.delete(event)
            }
        }
        onDeleted?()
        modelContext.delete(person)
        dismiss()
    }
}

private struct PersonEventRow: View {
    let ep: EventPerson
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: event.category.color).opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(event.displayEmoji)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(ep.totalSpent.currencyFormatted)
                        .font(.system(size: 12))
                        .foregroundStyle(ep.isOverBudget ? AppColors.barRed : AppColors.textSecondary)
                    if ep.budget > 0 {
                        Text("of \(ep.budget.currencyFormatted)")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(ep.purchases.count) item\(ep.purchases.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textSecondary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
        .contentShape(Rectangle())
    }
}
