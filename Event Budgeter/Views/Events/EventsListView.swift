//
//  EventsListView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct EventsListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navState: TabNavigationState
    @Query private var events: [Event]

    @State private var showingAdd = false
    @State private var toast: ToastMessage?

    private var visibleEvents: [Event] { events.filter { !$0.isHidden } }

    private var grouped: [(EventCategory, [Event])] {
        let byCategory = Dictionary(grouping: visibleEvents) { $0.category }
        return EventCategory.allCases.compactMap { cat in
            guard let items = byCategory[cat], !items.isEmpty else { return nil }
            let sorted = items.sorted { a, b in
                let aDate = a.nextOccurrence ?? .distantFuture
                let bDate = b.nextOccurrence ?? .distantFuture
                return aDate < bDate
            }
            return (cat, sorted)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "calendar.badge.plus",
                        description: Text("Add birthdays, anniversaries, and holidays to get started.")
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.0) { category, items in
                            Section(category.label) {
                                ForEach(items) { event in
                                    NavigationLink {
                                        EventDetailView(event: event, onDeleted: {
                                            toast = .success("Event deleted")
                                        })
                                    } label: {
                                        EventRow(event: event)
                                    }
                                }
                                .onDelete { offsets in
                                    delete(items: items, offsets: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                if !visibleEvents.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
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

    private func delete(items: [Event], offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(items[i])
        }
        toast = .success(offsets.count == 1 ? "Event deleted" : "\(offsets.count) events deleted")
    }
}

private struct EventRow: View {
    let event: Event

    var body: some View {
        HStack(spacing: 12) {
            Text(event.displayEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(hex: event.category.color).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    Text(event.nextOccurrenceFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let days = event.daysUntilNext {
                        if days == 0 {
                            Text("Today")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .fontWeight(.semibold)
                        } else if days <= 30 {
                            Text("in \(days)d")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if !event.assignments.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(event.assignments.prefix(3).compactMap { $0.person }) { person in
                            Circle()
                                .fill(Color(hex: person.colorHex))
                                .frame(width: 20, height: 20)
                                .overlay {
                                    Text(String(person.initials.prefix(1)))
                                        .font(.system(size: 9))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                        }
                    }
                    if event.assignments.count > 3 {
                        Text("+\(event.assignments.count - 3)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
