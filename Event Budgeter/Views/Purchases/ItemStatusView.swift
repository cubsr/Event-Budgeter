//
//  ItemStatusView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct ItemStatusView: View {
    @Query private var allPurchases: [PurchaseItem]
    @Query private var allGiftItems: [GiftItem]

    private var purchasesByStatus: [ItemStatus: [PurchaseItem]] {
        Dictionary(grouping: allPurchases, by: \.status)
    }

    private var giftItemsByStatus: [ItemStatus: [GiftItem]] {
        Dictionary(grouping: allGiftItems, by: \.status)
    }

    var body: some View {
        NavigationStack {
            Group {
                if allPurchases.isEmpty && allGiftItems.isEmpty {
                    ContentUnavailableView(
                        "No Items Yet",
                        systemImage: "checklist",
                        description: Text("Add items to events to track their status here.")
                    )
                } else {
                    List {
                        ForEach(ItemStatus.allCases) { status in
                            let purchases = purchasesByStatus[status] ?? []
                            let giftItems = giftItemsByStatus[status] ?? []
                            let total = purchases.count + giftItems.count
                            if total > 0 {
                                Section {
                                    ForEach(purchases) { item in
                                        PurchaseStatusRow(item: item)
                                    }
                                    ForEach(giftItems) { item in
                                        GiftItemStatusRow(item: item)
                                    }
                                } header: {
                                    HStack(spacing: 6) {
                                        Image(systemName: status.icon)
                                            .foregroundStyle(status.color)
                                        Text(status.label)
                                            .foregroundStyle(status.color)
                                        Spacer()
                                        Text("\(total)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Items")
        }
    }
}

private struct PurchaseStatusRow: View {
    let item: PurchaseItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.name)
                .fontWeight(.medium)
            HStack(spacing: 4) {
                if let person = item.eventPerson?.person {
                    Text(person.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let event = item.eventPerson?.event {
                    Text("· \(event.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if item.cost > 0 {
                    Text(item.cost.currencyFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct GiftItemStatusRow: View {
    let item: GiftItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.name)
                    .fontWeight(.medium)
                Image(systemName: "square.stack")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
            HStack(spacing: 4) {
                Text("\(item.assignments.count) recipient\(item.assignments.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if item.cost > 0 {
                    Text(item.cost.currencyFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
