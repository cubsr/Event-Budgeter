//
//  PurchaseListView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct PurchaseListView: View {
    @Environment(\.modelContext) private var modelContext
    let eventPerson: EventPerson

    @State private var showingAdd = false
    @State private var showingIdeaPicker = false
    @State private var editingPurchase: PurchaseItem?
    @State private var showingBudgetEdit = false

    private var sortedPurchases: [PurchaseItem] {
        eventPerson.purchases.sorted { $0.purchaseDate > $1.purchaseDate }
    }

    private var personName: String { eventPerson.person?.name ?? "Person" }
    private var eventName: String  { eventPerson.event?.title ?? "Event" }

    var body: some View {
        ZStack {
            AppColors.appBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    // Budget summary card
                    VStack(spacing: 10) {
                        HStack {
                            Text("$\(NSDecimalNumber(decimal: eventPerson.totalSpent).intValue)")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundStyle(eventPerson.isOverBudget ? AppColors.barRed : .primary)
                            Text("of $\(NSDecimalNumber(decimal: eventPerson.budget).intValue)")
                                .font(.system(size: 17))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                            if eventPerson.isOverBudget {
                                Label("Over budget", systemImage: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColors.barRed)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.barRed.opacity(0.1))
                                    .clipShape(Capsule())
                            } else if eventPerson.budget > 0 {
                                Text("$\(NSDecimalNumber(decimal: eventPerson.remainingBudget).intValue) left")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColors.barGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(AppColors.barGreen.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }

                        if eventPerson.budget > 0 {
                            BudgetProgressBar(spent: eventPerson.totalSpent, budget: eventPerson.budget, currency: "$")
                        }

                        Divider()

                        Button {
                            showingBudgetEdit = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundStyle(AppColors.accent)
                                Text(eventPerson.budget > 0 ? "Edit Budget" : "Set Budget")
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

                    // Items section
                    VStack(spacing: 0) {
                        if sortedPurchases.isEmpty {
                            Button { showingAdd = true } label: {
                                VStack(spacing: 10) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 38))
                                        .foregroundStyle(AppColors.accentMid)
                                    Text("No items yet")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.textSecondary)
                                    Text("Tap here to add your first item")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(sortedPurchases) { item in
                                PurchaseRow(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editingPurchase = item }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)

                                if item.persistentModelID != sortedPurchases.last?.persistentModelID {
                                    Divider().padding(.leading, 66)
                                }
                            }
                        }

                        Divider()

                        // Inline add buttons
                        HStack(spacing: 0) {
                            Button { showingAdd = true } label: {
                                Label("New Item", systemImage: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)

                            Divider().frame(height: 22)

                            Button { showingIdeaPicker = true } label: {
                                Label("From Ideas", systemImage: "lightbulb")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.accent)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(AppColors.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
                    .padding(.horizontal, 16)

                    // Footer summary
                    if !sortedPurchases.isEmpty {
                        let needCount = sortedPurchases.filter { $0.status == .need }.count
                        HStack {
                            Text("\(eventPerson.giftedCount) gifted · \(needCount) still needed")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 14)
            }
        }
        .navigationTitle("\(personName) · \(eventName)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBudgetEdit) {
            EditEventPersonBudgetSheet(eventPerson: eventPerson)
        }
        .sheet(isPresented: $showingAdd) {
            AddEditPurchaseView(eventPerson: eventPerson)
        }
        .sheet(item: $editingPurchase) { item in
            AddEditPurchaseView(eventPerson: eventPerson, purchase: item)
        }
        .sheet(isPresented: $showingIdeaPicker) {
            GiftIdeaPickerSheet(eventPerson: eventPerson)
        }
    }

    private func delete(offsets: IndexSet) {
        let items = sortedPurchases
        for i in offsets {
            modelContext.delete(items[i])
        }
    }
}

private struct PurchaseRow: View {
    let item: PurchaseItem

    var body: some View {
        HStack(spacing: 12) {
            // Photo or status icon
            if let data = item.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.status.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: item.status.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(item.status.color)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(item.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                    if !item.storeName.isEmpty {
                        Text("· \(item.storeName)")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    } else if !item.notes.isEmpty {
                        Text("· \(item.notes)")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if item.cost > 0 {
                    Text("$\(NSDecimalNumber(decimal: item.cost).intValue)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }
                // Status badge
                HStack(spacing: 3) {
                    Text(item.status.icon)
                        .font(.system(size: 10))
                    Text(item.status.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(item.status.color)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(item.status.color.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}
