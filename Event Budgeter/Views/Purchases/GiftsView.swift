//
//  GiftsView.swift
//  Event Budgeter
//
//  Split into two surfaces:
//  - Tracked: concrete PurchaseItems flowing through need → have → wrap → gift
//  - Ideas: reusable GiftIdea templates
//

import SwiftUI
import SwiftData

struct GiftsView: View {
    @Query private var allPurchases: [PurchaseItem]
    @Query(sort: \GiftIdea.name) private var allIdeas: [GiftIdea]
    @Query private var events: [Event]
    @Query(sort: \Person.name) private var people: [Person]

    @State private var selectedSurface: Surface = .tracked
    @State private var statusFilter: ItemStatus? = nil
    @State private var groupBy: GiftGroupBy = .status
    @State private var showingAddSheet = false
    @State private var editingPurchase: PurchaseItem? = nil
    @State private var editingIdea: GiftIdea? = nil

    enum Surface: String, CaseIterable {
        case tracked = "Tracked"
        case ideas = "Ideas"
    }

    enum GiftGroupBy: String, CaseIterable {
        case status = "Status"
        case event  = "Event"
        case person = "Person"
    }

    // MARK: - Tracked surface

    private var filteredPurchases: [PurchaseItem] {
        guard let f = statusFilter else { return allPurchases }
        return allPurchases.filter { $0.status == f }
    }

    private var pipelineCounts: [(ItemStatus, Int, Decimal)] {
        ItemStatus.allCases.map { s in
            let items = allPurchases.filter { $0.status == s }
            let total = items.reduce(Decimal(0)) { $0 + $1.cost }
            return (s, items.count, total)
        }
    }

    private var committedSpend: Decimal {
        allPurchases.filter { [.wrap, .gift].contains($0.status) }.reduce(Decimal(0)) { $0 + $1.cost }
    }
    private var plannedSpend: Decimal {
        allPurchases.filter { [.need, .have].contains($0.status) }.reduce(Decimal(0)) { $0 + $1.cost }
    }
    private var totalSpend: Decimal {
        allPurchases.reduce(Decimal(0)) { $0 + $1.cost }
    }

    private var groupedPurchases: [(key: String, icon: String, isSystemIcon: Bool, items: [PurchaseItem])] {
        switch groupBy {
        case .status:
            return ItemStatus.allCases.compactMap { s in
                let items = filteredPurchases.filter { $0.status == s }
                guard !items.isEmpty else { return nil }
                return (key: s.label, icon: s.icon, isSystemIcon: true, items: items)
            }
        case .event:
            var groups: [(key: String, icon: String, isSystemIcon: Bool, items: [PurchaseItem])] = []
            for event in events {
                let items = filteredPurchases.filter { $0.eventPerson?.event?.persistentModelID == event.persistentModelID }
                guard !items.isEmpty else { continue }
                groups.append((key: event.title, icon: event.displayEmoji, isSystemIcon: false, items: items))
            }
            return groups
        case .person:
            var groups: [(key: String, icon: String, isSystemIcon: Bool, items: [PurchaseItem])] = []
            for person in people {
                let items = filteredPurchases.filter { $0.eventPerson?.person?.persistentModelID == person.persistentModelID }
                guard !items.isEmpty else { continue }
                groups.append((key: person.name, icon: "👤", isSystemIcon: false, items: items))
            }
            return groups
        }
    }

    // MARK: - Ideas surface

    private var displayedIdeas: [GiftIdea] {
        // Cash Gift sticks to the top
        let cash = allIdeas.filter { $0.isCashGift }
        let rest = allIdeas.filter { !$0.isCashGift }
        return cash + rest
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerRow

                    surfacePicker
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)

                    if selectedSurface == .tracked {
                        trackedSurface
                    } else {
                        ideasSurface
                    }
                }

                FABButton { showingAddSheet = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                if selectedSurface == .tracked {
                    GiftAddSheet(events: events)
                } else {
                    AddEditGiftIdeaView()
                }
            }
            .sheet(item: $editingPurchase) { item in
                if let ep = item.eventPerson {
                    AddEditPurchaseView(eventPerson: ep, purchase: item)
                }
            }
            .sheet(item: $editingIdea) { idea in
                AddEditGiftIdeaView(giftIdea: idea)
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Gifts")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            if selectedSurface == .tracked {
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var surfacePicker: some View {
        Picker("Surface", selection: $selectedSurface) {
            ForEach(Surface.allCases, id: \.self) { s in
                Text(s.rawValue).tag(s)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Tracked surface

    private var trackedSurface: some View {
        VStack(spacing: 0) {
            // Pipeline strip — centered four-stage filter
            HStack(spacing: 8) {
                ForEach(pipelineCounts, id: \.0) { status, count, _ in
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
                    .frame(maxWidth: .infinity)
                    .opacity(count == 0 ? 0.45 : 1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

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

            // Purchases list
            if allPurchases.isEmpty {
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
                        ForEach(groupedPurchases, id: \.key) { section in
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

                            ForEach(section.items) { item in
                                PurchaseCard(
                                    item: item,
                                    people: people,
                                    onAdvance: { advanceStatus(item) },
                                    onTap: { editingPurchase = item }
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
    }

    // MARK: - Ideas surface

    private var ideasSurface: some View {
        Group {
            if displayedIdeas.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "lightbulb")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.textTertiary)
                    Text("No ideas yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to save a reusable gift idea")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(displayedIdeas) { idea in
                            IdeaCard(idea: idea) { editingIdea = idea }
                                .padding(.horizontal, 16)
                        }
                        Color.clear.frame(height: 80)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Helpers

    private func advanceStatus(_ item: PurchaseItem) {
        let all = ItemStatus.allCases
        guard let idx = all.firstIndex(of: item.status), idx < all.count - 1 else { return }
        item.status = all[idx + 1]
    }
}

// MARK: - Purchase Card

private struct PurchaseCard: View {
    let item: PurchaseItem
    let people: [Person]
    let onAdvance: () -> Void
    let onTap: () -> Void

    private var person: Person? { item.eventPerson?.person }
    private var event: Event? { item.eventPerson?.event }
    private var isLastStatus: Bool { item.status == .gift }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let person {
                    PersonAvatarView(person: person, size: 38)
                } else {
                    Circle()
                        .fill(AppColors.accentSoft)
                        .frame(width: 38, height: 38)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name.isEmpty ? "Unnamed gift" : item.name)
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

                    if !item.notes.isEmpty {
                        Text("\"\(item.notes)\"")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textTertiary)
                            .italic()
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 6) {
                    if item.cost > 0 {
                        Text("$\(NSDecimalNumber(decimal: item.cost).intValue)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.primary)
                    }

                    Button {
                        onAdvance()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: item.status.icon)
                                .font(.system(size: 11))
                            Text(item.status.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(item.status.color)
                            if !isLastStatus {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(item.status.color)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.status.color.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isLastStatus)
                    .opacity(isLastStatus ? 0.7 : 1)
                }
            }
            .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Idea Card

private struct IdeaCard: View {
    let idea: GiftIdea
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "#A78BFA").opacity(0.12))
                        .frame(width: 40, height: 40)
                    if idea.isCashGift {
                        Text("💵").font(.system(size: 20))
                    } else if let data = idea.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: "#A78BFA"))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(idea.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    if !idea.storeName.isEmpty {
                        Text(idea.storeName)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textSecondary)
                    } else if !idea.notes.isEmpty {
                        Text(idea.notes)
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                if idea.cost > 0 {
                    Text("$\(NSDecimalNumber(decimal: idea.cost).intValue)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            VStack(spacing: 4) {
                Image(systemName: systemIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isActive ? activeTextColor : AppColors.textSecondary)
                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isActive ? activeTextColor : .primary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isActive ? activeTextColor.opacity(0.85) : AppColors.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
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

// MARK: - Gift Add Sheet (for the Tracked surface)

struct GiftAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let events: [Event]

    @State private var selectedEventPerson: EventPerson? = nil

    private var allEventPersons: [EventPerson] {
        events.flatMap { $0.assignments }.filter { $0.person != nil }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        if allEventPersons.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 36))
                                    .foregroundStyle(AppColors.textTertiary)
                                Text("Assign people to events first")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Gifts are always tracked for a specific person and event.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                            .padding(.horizontal, 32)
                        } else {
                            HStack {
                                Text("FOR A PERSON")
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
                                        .contentShape(Rectangle())
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
        }
    }
}
