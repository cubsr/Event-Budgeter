//
//  EventDetailView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let event: Event

    @State private var showingEdit = false
    @State private var showingAssign = false
    @State private var editingEventPerson: EventPerson?
    @State private var showingBudgetEdit = false
    @State private var showingEventBudgetEdit = false
    @State private var eventBudgetString = ""
    @State private var showingDeleteConfirm = false

    private var sortedAssignments: [EventPerson] {
        event.assignments.compactMap { $0.person != nil ? $0 : nil }
            .sorted { ($0.person?.name ?? "") < ($1.person?.name ?? "") }
    }

    private var boughtGifts: [PurchaseItem] {
        event.assignments
            .flatMap { $0.purchases }
            .sorted { $0.purchaseDate > $1.purchaseDate }
    }

    var body: some View {
        ZStack {
            AppColors.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    // Event header card
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: event.category.color).opacity(0.15))
                                .frame(width: 60, height: 60)
                            Text(event.displayEmoji)
                                .font(.system(size: 30))
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text(event.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.primary)

                            HStack(spacing: 6) {
                                Text(event.category.label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: event.category.color))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: event.category.color).opacity(0.12))
                                    .clipShape(Capsule())

                                Text(event.recurrenceRule.label)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            if let next = event.nextOccurrence {
                                Text(next.formatted(date: .long, time: .omitted))
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                        Spacer()
                    }
                    .bubbleCard()
                    .padding(.horizontal, 16)

                    if !event.notes.isEmpty {
                        HStack {
                            Text(event.notes)
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)
                    }

                    // Budget summary card
                    VStack(spacing: 10) {
                        HStack {
                            Text("Budget Summary")
                                .sectionHeaderStyle()
                            Spacer()
                        }

                        // Tappable total budget row
                        Button {
                            eventBudgetString = event.eventBudget != nil ? "\(event.eventBudget!)" : ""
                            showingEventBudgetEdit = true
                        } label: {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundStyle(AppColors.accent)
                                    Text("Total Budget")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Text("$\(NSDecimalNumber(decimal: event.displayBudget).intValue)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.textSecondary)
                                if event.eventBudget != nil {
                                    Image(systemName: "pencil.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColors.accentMid)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "cart.fill")
                                    .foregroundStyle(AppColors.barGreen)
                                Text("Total Spent")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Text("$\(NSDecimalNumber(decimal: event.totalSpent).intValue)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(event.totalSpent > event.displayBudget && event.displayBudget > 0 ? AppColors.barRed : AppColors.textSecondary)
                        }

                        if event.displayBudget > 0 {
                            BudgetProgressBar(spent: event.totalSpent, budget: event.displayBudget, currency: "$")
                        }

                        Divider()

                        Button {
                            showingBudgetEdit = true
                        } label: {
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                                Text("Edit Budgets")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.accent)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .bubbleCard()
                    .padding(.horizontal, 16)

                    // Gifts bought across the event
                    if !boughtGifts.isEmpty {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Gifts")
                                    .sectionHeaderStyle()
                                Spacer()
                                Text("\(boughtGifts.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.accentSoft)
                                    .clipShape(Capsule())
                            }

                            ForEach(boughtGifts) { item in
                                EventGiftRow(item: item)
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)
                    }

                    // People
                    VStack(spacing: 10) {
                        HStack {
                            Text("People")
                                .sectionHeaderStyle()
                            Spacer()
                            Button {
                                showingAssign = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                            }
                        }

                        if sortedAssignments.isEmpty {
                            Text("No people assigned yet.")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        }

                        ForEach(sortedAssignments) { ep in
                            if let person = ep.person {
                                NavigationLink {
                                    PurchaseListView(eventPerson: ep)
                                } label: {
                                    PersonBudgetRow(ep: ep, person: person)
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
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(ep)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .bubbleCard()
                    .padding(.horizontal, 16)

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 14)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Edit Event") { showingEdit = true }
                Divider()
                if event.category == .birthday {
                    Button(event.isHidden ? "Unhide Birthday" : "Hide Birthday") {
                        event.isHidden.toggle()
                        if event.isHidden { dismiss() }
                    }
                } else {
                    Button("Delete Event", role: .destructive) {
                        showingDeleteConfirm = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(AppColors.accent)
            }
        }
        .confirmationDialog(
            "Delete \"\(event.title)\"?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                modelContext.delete(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the event and all associated purchases.")
        }
        .sheet(isPresented: $showingEdit) {
            AddEditEventView(event: event)
        }
        .sheet(isPresented: $showingBudgetEdit) {
            EditEventBudgetsSheet(event: event)
        }
        .sheet(isPresented: $showingAssign) {
            AssignPersonSheet(event: event)
        }
        .sheet(item: $editingEventPerson) { ep in
            EditEventPersonBudgetSheet(eventPerson: ep)
        }
        .alert("Set Event Budget", isPresented: $showingEventBudgetEdit) {
            TextField("Amount", text: $eventBudgetString)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let val = Decimal(string: eventBudgetString.replacingOccurrences(of: ",", with: ".")), val > 0 {
                    event.eventBudget = val
                } else {
                    event.eventBudget = nil
                }
            }
            Button("Clear Override") { event.eventBudget = nil }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Override the sum of individual budgets, or clear to use per-person totals.")
        }
    }
}

private struct EventGiftRow: View {
    let item: PurchaseItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.status.color.opacity(0.12))
                    .frame(width: 36, height: 36)
                if let data = item.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    Image(systemName: item.status.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(item.status.color)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let person = item.eventPerson?.person {
                    Text("for \(person.name)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if item.cost > 0 {
                    Text("$\(NSDecimalNumber(decimal: item.cost).intValue)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Text(item.status.label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(item.status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(item.status.color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}

private struct PersonBudgetRow: View {
    let ep: EventPerson
    let person: Person

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatarView(person: person, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                if ep.budget > 0 {
                    BudgetProgressBar(spent: ep.totalSpent, budget: ep.budget, currency: "$")
                } else {
                    HStack(spacing: 4) {
                        Text("$\(NSDecimalNumber(decimal: ep.totalSpent).intValue) spent · no budget set")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.accentMid)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(ep.purchases.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(AppColors.accentMid)
                    .clipShape(Circle())

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
