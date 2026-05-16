//
//  EventsTabView.swift
//  Event Budgeter
//

import SwiftUI

enum EventsSubTab {
    case upcoming, calendar, byCategory
}

struct EventsTabView: View {
    @EnvironmentObject private var navState: TabNavigationState
    @State private var subTab: EventsSubTab = .upcoming
    @State private var showingAdd = false
    @State private var toast: ToastMessage?

    private var deleteToast: () -> Void {
        { toast = .success("Event deleted") }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("View", selection: $subTab) {
                        Text("Upcoming").tag(EventsSubTab.upcoming)
                        Text("Calendar").tag(EventsSubTab.calendar)
                        Text("By Category").tag(EventsSubTab.byCategory)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 4)

                    Group {
                        switch subTab {
                        case .upcoming:
                            UpcomingEventsView(onDeleted: deleteToast)
                        case .calendar:
                            CalendarTabView(onDeleted: deleteToast)
                        case .byCategory:
                            EventsByCategoryView(toast: $toast)
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
                AddEditEventView(onSaved: { toast = .success("Event created") })
            }
            .toast(message: $toast)
        }
        // Recreating the stack on reset pops any pushed detail view back to root.
        // The sheet reset lives outside the stack so it isn't torn down by the
        // .id() change and can clear the flag before the new stack reads it.
        .id(navState.resetCounters[.events])
        .onChange(of: navState.resetCounters[.events]) {
            showingAdd = false
        }
    }
}
