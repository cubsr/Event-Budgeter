//
//  EventsTabView.swift
//  Event Budgeter
//

import SwiftUI

enum EventsSubTab {
    case upcoming, calendar
}

struct EventsTabView: View {
    @State private var subTab: EventsSubTab = .upcoming
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("View", selection: $subTab) {
                        Text("Upcoming").tag(EventsSubTab.upcoming)
                        Text("Calendar").tag(EventsSubTab.calendar)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    Group {
                        switch subTab {
                        case .upcoming:
                            UpcomingEventsView()
                        case .calendar:
                            CalendarTabView()
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: subTab)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                FABButton { showingAdd = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAdd) {
                AddEditEventView()
            }
        }
    }
}
