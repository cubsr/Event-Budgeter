//
//  PeopleListView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var people: [Person]

    @State private var showingAdd = false
    @State private var personToDelete: Person?
    private let currentYear = Calendar.current.component(.year, from: .now)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                if people.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundStyle(AppColors.accentMid)
                        Text("No people yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add the people you buy gifts for.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(people) { person in
                                NavigationLink {
                                    PersonDetailView(person: person)
                                } label: {
                                    PersonRow(person: person, year: currentYear)
                                        .padding(.horizontal, 16)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        personToDelete = person
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            Color.clear.frame(height: 80)
                        }
                        .padding(.top, 14)
                    }
                }

                FABButton { showingAdd = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
            .navigationTitle("People")
            .sheet(isPresented: $showingAdd) {
                AddEditPersonView()
            }
            .confirmationDialog(
                "Delete \(personToDelete?.name ?? "person")?",
                isPresented: Binding(get: { personToDelete != nil }, set: { if !$0 { personToDelete = nil } }),
                titleVisibility: .visible,
                presenting: personToDelete
            ) { person in
                Button("Delete", role: .destructive) {
                    deletePerson(person)
                    personToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    personToDelete = nil
                }
            } message: { person in
                Text("This removes \(person.name) and any birthday event tied to them.")
            }
        }
    }

    private func deletePerson(_ person: Person) {
        for ep in person.assignments {
            if let event = ep.event, event.category == .birthday {
                NotificationManager.cancelNotification(for: event)
                modelContext.delete(event)
            }
        }
        modelContext.delete(person)
    }
}

private struct PersonRow: View {
    let person: Person
    let year: Int

    var body: some View {
        HStack(spacing: 12) {
            PersonAvatarView(person: person, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                if !person.relationshipLabel.isEmpty {
                    Text(person.relationshipLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            let yearSpend = person.totalSpent(inYear: year)
            if yearSpend > 0 {
                Text("$\(NSDecimalNumber(decimal: yearSpend).intValue)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundStyle(AppColors.textTertiary)
        }
        .bubbleCard(padding: .init(top: 12, leading: 12, bottom: 12, trailing: 12))
        .contentShape(Rectangle())
    }
}
