//
//  DayDetailSheet.swift
//  Event Budgeter
//

import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    let events: [Event]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(events) { event in
                NavigationLink {
                    EventDetailView(event: event)
                } label: {
                    HStack(spacing: 12) {
                        Text(event.displayEmoji)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .fontWeight(.medium)
                            Text(event.category.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(date.formatted(date: .complete, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
