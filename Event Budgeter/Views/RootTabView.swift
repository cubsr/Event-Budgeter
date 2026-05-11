//
//  RootTabView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvents: [Event]
    @Query(filter: #Predicate<GiftIdea> { $0.isCashGift }) private var cashGiftIdeas: [GiftIdea]
    @AppStorage("upcomingSheetLastShown") private var lastShownDate: String = ""
    @State private var showingUpcomingSheet = false
    @State private var selectedTab: AppTab = .events

    private var upcomingEvents: [(event: Event, daysUntil: Int)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        guard let cutoff = cal.date(byAdding: .day, value: 90, to: today) else { return [] }
        return allEvents.compactMap { event -> (Event, Int)? in
            guard let next = event.nextOccurrence, next >= today, next <= cutoff else { return nil }
            let days = cal.dateComponents([.day], from: today, to: next).day ?? 0
            return (event, days)
        }
        .sorted { $0.1 < $1.1 }
    }

    private var todayISO: String {
        let today = Calendar.current.startOfDay(for: .now)
        return ISO8601DateFormatter().string(from: today)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content area fills remaining space
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                Group {
                    switch selectedTab {
                    case .events:
                        EventsTabView()
                    case .gifts:
                        GiftsView()
                    case .people:
                        PeopleListView()
                    case .reports:
                        ReportsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Tab bar sits below content, above device safe area
            CustomTabBar(selectedTab: $selectedTab)
        }
        .onAppear {
            seedCashGiftIfNeeded()
            guard !upcomingEvents.isEmpty, lastShownDate != todayISO else { return }
            showingUpcomingSheet = true
            lastShownDate = todayISO
        }
        .sheet(isPresented: $showingUpcomingSheet) {
            UpcomingEventsLaunchSheet(upcomingEvents: upcomingEvents) {
                showingUpcomingSheet = false
            }
        }
    }

    private func seedCashGiftIfNeeded() {
        guard cashGiftIdeas.isEmpty else { return }
        let cashGift = GiftIdea(
            name: "Cash Gift",
            cost: 0,
            notes: "Enter the amount given each time.",
            isCashGift: true
        )
        modelContext.insert(cashGift)
    }
}

// MARK: - Tab enum

enum AppTab: String, CaseIterable {
    case events, gifts, people, reports

    var label: String {
        switch self {
        case .events:   return "Events"
        case .gifts:    return "Gifts"
        case .people:   return "People"
        case .reports:  return "Reports"
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        TabIcon(tab: tab, active: selectedTab == tab)
                            .frame(width: 22, height: 22)
                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .regular))
                            .foregroundStyle(selectedTab == tab ? AppColors.tabActive : AppColors.tabInactive)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            AppColors.tabBarBg
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AppColors.tabBarBorder)
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Tab Icons

struct TabIcon: View {
    let tab: AppTab
    let active: Bool

    private var color: Color { active ? AppColors.tabActive : AppColors.tabInactive }

    private var systemName: String {
        switch tab {
        case .events:   return active ? "list.bullet.clipboard.fill" : "list.bullet.clipboard"
        case .gifts:    return active ? "gift.fill"                  : "gift"
        case .people:   return active ? "person.2.fill"              : "person.2"
        case .reports:  return active ? "chart.bar.fill"             : "chart.bar"
        }
    }

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 20, weight: active ? .semibold : .regular))
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
    }
}
