//
//  GiftsView.swift
//  Event Budgeter
//
//  Pipeline strip + grouped gift list using the current ItemStatus model.
//

import SwiftUI
import SwiftData

struct GiftsView: View {
    @Query private var allPurchases: [PurchaseItem]
    @Query private var allGiftItems: [GiftItem]
    @Query private var events: [Event]
    @Query(sort: \Person.name) private var people: [Person]

    @State private var statusFilter: ItemStatus? = nil
    @State private var groupBy: GiftGroupBy = .status
    @State private var showingAdd = false
    @State private var editingPurchase: PurchaseItem? = nil
    @State private var editingGiftItem: GiftItem? = nil

    enum GiftGroupBy: String, CaseIterable {
        case status = "Status"
        case event  = "Event"
        case person = "Person"
    }

    // All "gift-like" items in a unified wrapper
    private var allGifts: [AnyGift] {
        let purchases = allPurchases.map { AnyGift(purchase: $0) }
        let templates = allGiftItems.map { AnyGift(giftItem: $0) }
        return (purchases + templates).sorted { $0.name < $1.name }
    }

    private var filtered: [AnyGift] {
        guard let f = statusFilter else { return allGifts }
        return allGifts.filter { $0.status == f }
    }

    // Pipeline counts
    private var pipelineCounts: [(ItemStatus, Int, Decimal)] {
        ItemStatus.allCases.map { s in
            let items = allGifts.filter { $0.status == s }
            let total = items.reduce(Decimal(0)) { $0 + $1.cost }
            return (s, items.count, total)
        }
    }

    // Summary totals
    private var committedSpend: Decimal {
        allGifts.filter { [.wrap, .gift].contains($0.status) }.reduce(Decimal(0)) { $0 + $1.cost }
    }
    private var plannedSpend: Decimal {
        allGifts.filter { [.need, .have].contains($0.status) }.reduce(Decimal(0)) { $0 + $1.cost }
    }
    private var totalSpend: Decimal {
        allGifts.reduce(Decimal(0)) { $0 + $1.cost }
    }

    // Grouped items
    private var grouped: [(key: String, icon: String, isSystemIcon: Bool, items: [AnyGift])] {
        switch groupBy {
        case .status:
            return ItemStatus.allCases.compactMap { s in
                let items = filtered.filter { $0.status == s }
                guard !items.isEmpty else { return nil }
                return (key: s.label, icon: s.icon, isSystemIcon: true, items: items)
            }
        case .event:
            var groups: [(key: String, icon: String, isSystemIcon: Bool, items: [AnyGift])] = []
            for event in events {
                let items = filtered.filter { $0.eventID == event.persistentModelID }
                guard !items.isEmpty else { continue }
                groups.append((key: event.title, icon: event.displayEmoji, isSystemIcon: false, items: items))
            }
            let ungrouped = filtered.filter { $0.eventID == nil }
            if !ungrouped.isEmpty {
                groups.append((key: "No Event", icon: "📦", isSystemIcon: false, items: ungrouped))
            }
            return groups
        case .person:
            var groups: [(key: String, icon: String, isSystemIcon: Bool, items: [AnyGift])] = []
            for person in people {
                let items = filtered.filter { $0.personID == person.persistentModelID }
                guard !items.isEmpty else { continue }
                groups.append((key: person.name, icon: "👤", isSystemIcon: false, items: items))
            }
            let ungrouped = filtered.filter { $0.personID == nil }
            if !ungrouped.isEmpty {
                groups.append((key: "No Person", icon: "👤", isSystemIcon: false, items: ungrouped))
            }
            return groups
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("Gifts")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        // Group-by chips
                        HStack(spacing: 4) {
                            ForEach(GiftGroupBy.allCases, id: \.self) { g in
                                Button {
                                    groupBy = g
                                } label: {
                                    Text(g.rawValue)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(groupBy == g ? .white : AppColors.accentText)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(groupBy == g ? AppColors.accent : AppColors.accentSoft)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 10)

                    // Pipeline strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            // "All" pill
                            PipelinePill(
                                systemIcon: "square.grid.2x2",
                                label: "All",
                                count: allGifts.count,
                                isActive: statusFilter == nil,
                                activeColor: AppColors.accent,
                                activeBg: AppColors.accent,
                                activeTextColor: .white
                            ) { statusFilter = nil }

                            ForEach(pipelineCounts, id: \.0) { status, count, _ in
                                HStack(spacing: 0) {
                                    Text("›")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppColors.textTertiary)
                                        .padding(.horizontal, 2)

                                    PipelinePill(
                                        systemIcon: status.icon,
                                        label: status.label,
                                        count: count,
                                        isActive: statusFilter == status,
                                        activeColor: status.color,
                                        activeBg: status.color.opacity(0.12),
                                        activeTextColor: status.color,
                                        borderColor: status.color
                                    ) {
                                        statusFilter = statusFilter == status ? nil : status
                                    }
                                    .opacity(count == 0 ? 0.45 : 1)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                    }

                    // Summary strip
                    HStack(spacing: 0) {
                        ForEach([
                            ("Committed", "$\(NSDecimalNumber(decimal: committedSpend).intValue)", AppColors.statusGift),
                            ("Planned",   "$\(NSDecimalNumber(decimal: plannedSpend).intValue)",   AppColors.statusNeed),
                            ("Total",     "$\(NSDecimalNumber(decimal: totalSpend).intValue)",     AppColors.accent),
                        ], id: \.0) { label, value, color in
                            VStack(spacing: 2) {
                                Text(value)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(color)
                                Text(label)
                                    .font(.system(size: 10))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .leading) {
                                if label != "Committed" {
                                    Rectangle()
                                        .fill(Color(hex: "#E5E7EB"))
                                        .frame(width: 0.5)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .bubbleCard(padding: .init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)

                    // Gift list
                    if allGifts.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Text("🎁")
                                .font(.system(size: 48))
                            Text("No gifts yet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Tap + to track your first gift")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(grouped, id: \.key) { section in
                                    // Section header
                                    HStack(spacing: 6) {
                                        if section.isSystemIcon {
                                            Image(systemName: section.icon)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(AppColors.textSecondary)
                                        } else {
                                            Text(section.icon)
                                                .font(.system(size: 13))
                                        }
                                        Text(section.key)
                                            .sectionHeaderStyle()
                                        Text("(\(section.items.count))")
                                            .font(.system(size: 11))
                                            .foregroundStyle(AppColors.textTertiary)
                                        Spacer()
                                    }
                                    .padding(.leading, 20)
                                    .padding(.top, 14)
                                    .padding(.bottom, 8)

                                    ForEach(section.items) { gift in
                                        GiftCard(
                                            gift: gift,
                                            people: people,
                                            events: events,
                                            onAdvance: { advanceStatus(gift) },
                                            onTap: { openEdit(gift) }
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 8)
                                    }
                                }
                                Color.clear.frame(height: 80)
                            }
                        }
                    }
                }

                FABButton { showingAdd = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                GiftAddSheet(events: events)
            }
            .sheet(item: $editingPurchase) { item in
                if let ep = item.eventPerson {
                    AddEditPurchaseView(eventPerson: ep, purchase: item)
                }
            }
        }
    }

    // MARK: - Helpers

    private func advanceStatus(_ gift: AnyGift) {
        let all = ItemStatus.allCases
        guard let idx = all.firstIndex(of: gift.status), idx < all.count - 1 else { return }
        let next = all[idx + 1]
        if let p = gift.purchase { p.status = next }
        else if let g = gift.giftItem { g.status = next }
    }

    private func openEdit(_ gift: AnyGift) {
        if let p = gift.purchase { editingPurchase = p }
    }
}

// MARK: - AnyGift unified wrapper

struct AnyGift: Identifiable {
    let id: String
    let name: String
    let cost: Decimal
    let status: ItemStatus
    let notes: String
    let storeName: String
    let photoData: Data?

    let purchase: PurchaseItem?
    let giftItem: GiftItem?

    let eventID: PersistentIdentifier?
    let personID: PersistentIdentifier?

    init(purchase p: PurchaseItem) {
        self.id       = "p-\(p.persistentModelID)"
        self.name     = p.name
        self.cost     = p.cost
        self.status   = p.status
        self.notes    = p.notes
        self.storeName = p.storeName
        self.photoData = p.photoData
        self.purchase  = p
        self.giftItem  = nil
        self.eventID   = p.eventPerson?.event?.persistentModelID
        self.personID  = p.eventPerson?.person?.persistentModelID
    }

    init(giftItem g: GiftItem) {
        self.id        = "g-\(g.persistentModelID)"
        self.name      = g.name
        self.cost      = g.cost
        self.status    = g.status
        self.notes     = g.notes
        self.storeName = g.storeName
        self.photoData = g.photoData
        self.purchase  = nil
        self.giftItem  = g
        self.eventID   = g.assignments.first?.event?.persistentModelID
        self.personID  = g.assignments.first?.person?.persistentModelID
    }
}

// MARK: - Pipeline Pill

private struct PipelinePill: View {
    let systemIcon: String
    let label: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let activeBg: Color
    let activeTextColor: Color
    var borderColor: Color = .clear
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isActive ? activeTextColor : AppColors.textSecondary)
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isActive ? activeTextColor : .primary)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isActive ? activeTextColor.opacity(0.85) : AppColors.textTertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isActive ? activeBg : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isActive ? borderColor : .clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gift Card

private struct GiftCard: View {
    let gift: AnyGift
    let people: [Person]
    let events: [Event]
    let onAdvance: () -> Void
    let onTap: () -> Void

    private var person: Person? {
        guard let id = gift.personID else { return nil }
        return people.first { $0.persistentModelID == id }
    }

    private var event: Event? {
        guard let id = gift.eventID else { return nil }
        return events.first { $0.persistentModelID == id }
    }

    private var isLastStatus: Bool { gift.status == .gift }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Person avatar
                if let person {
                    PersonAvatarView(person: person, size: 38)
                } else {
                    Circle()
                        .fill(AppColors.accentSoft)
                        .frame(width: 38, height: 38)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(gift.name.isEmpty ? "Unnamed gift" : gift.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let event {
                            Text(event.displayEmoji)
                                .font(.system(size: 12))
                            Text(event.title)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        if let person, event != nil {
                            Text("·")
                                .foregroundStyle(AppColors.textTertiary)
                            Text(person.name)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)
                        } else if let person {
                            Text(person.name)
                                .font(.system(size: 11))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    if !gift.notes.isEmpty {
                        Text("\"\(gift.notes)\"")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textTertiary)
                            .italic()
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                // Price + status badge
                VStack(alignment: .trailing, spacing: 6) {
                    if gift.cost > 0 {
                        Text("$\(NSDecimalNumber(decimal: gift.cost).intValue)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        onAdvance()
                    } label: {
                        HStack(spacing: 3) {
                            Text(gift.status.icon)
                                .font(.system(size: 11))
                            Text(gift.status.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(gift.status.color)
                            if !isLastStatus {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(gift.status.color)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(gift.status.color.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLastStatus)
                    .opacity(isLastStatus ? 0.7 : 1)
                }
            }
        }
        .buttonStyle(.plain)
        .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

// MARK: - Gift Add Sheet (picks event → person, or creates a standalone idea)

struct GiftAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let events: [Event]

    @State private var selectedEventPerson: EventPerson? = nil
    @State private var showingStandaloneAdd = false

    private var allEventPersons: [EventPerson] {
        events.flatMap { $0.assignments }.filter { $0.person != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        // Standalone gift idea — always available
                        Button {
                            showingStandaloneAdd = true
                        } label: {
                            HStack(spacing: 12) {
                                Text("💡")
                                    .font(.system(size: 22))
                                    .frame(width: 40, height: 40)
                                    .background(AppColors.accentSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Gift idea")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text("No person or event required")
                                        .font(.system(size: 12))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppColors.textTertiary)
                            }
                            .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
                            .padding(.horizontal, 16)
                        }
                        .buttonStyle(.plain)

                        if !allEventPersons.isEmpty {
                            HStack {
                                Text("OR FOR A PERSON")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppColors.textTertiary)
                                    .padding(.leading, 20)
                                Spacer()
                            }
                            .padding(.top, 6)

                            ForEach(allEventPersons) { ep in
                                if let person = ep.person, let event = ep.event {
                                    Button {
                                        selectedEventPerson = ep
                                    } label: {
                                        HStack(spacing: 12) {
                                            Text(event.displayEmoji)
                                                .font(.system(size: 22))
                                                .frame(width: 40, height: 40)
                                                .background(Color(hex: event.category.color).opacity(0.15))
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(person.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                Text(event.title)
                                                    .font(.system(size: 12))
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11))
                                                .foregroundStyle(AppColors.textTertiary)
                                        }
                                        .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
                                        .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Color.clear.frame(height: 30)
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Add Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedEventPerson) { ep in
                AddEditPurchaseView(eventPerson: ep)
            }
            .sheet(isPresented: $showingStandaloneAdd) {
                AddEditGiftItemView()
            }
        }
    }
}
