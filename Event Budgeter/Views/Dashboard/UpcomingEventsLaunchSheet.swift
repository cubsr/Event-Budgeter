//
//  UpcomingEventsLaunchSheet.swift
//  Event Budgeter
//

import SwiftUI

struct UpcomingEventsLaunchSheet: View {
    let upcomingEvents: [(event: Event, daysUntil: Int)]
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(upcomingEvents, id: \.event.persistentModelID) { item in
                        HStack(spacing: 12) {
                            Text(item.event.displayEmoji)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.event.title)
                                    .fontWeight(.medium)
                                if let next = item.event.nextOccurrence {
                                    Text(next.formatted(date: .long, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if item.daysUntil == 0 {
                                Text("Today")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            } else {
                                Text("\(item.daysUntil)d")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                } header: {
                    Text("Upcoming in the next 90 days")
                }
            }
            .navigationTitle("Events Coming Up")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(action: onDismiss) {
                    Text("Got it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .presentationDetents([.medium, .large])
    }
}
