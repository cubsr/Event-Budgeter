//
//  PeopleListView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var navState: TabNavigationState
    @Query(sort: \Person.name) private var allPeople: [Person]

    @State private var showingAdd = false
    @State private var personToDelete: Person?
    @State private var showHidden = false
    @State private var searchText = ""
    @State private var toast: ToastMessage?
    private let currentYear = Calendar.current.component(.year, from: .now)

    private var people: [Person] {
        let base = showHidden ? allPeople : allPeople.filter { !$0.isHidden }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.displayRelationshipLabel.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppColors.appBg.ignoresSafeArea()

                if people.isEmpty && allPeople.isEmpty {
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
                                    PersonDetailView(
                                        person: person,
                                        onDeleted: { toast = .success("\(person.name) deleted") },
                                        onSaved: { toast = .success("Person updated") }
                                    )
                                } label: {
                                    PersonRow(person: person, year: currentYear)
                                        .padding(.horizontal, 16)
                                        .opacity(person.isHidden ? 0.5 : 1)
                                        .overlay(alignment: .topTrailing) {
                                            if person.isHidden {
                                                Image(systemName: "eye.slash")
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(AppColors.textTertiary)
                                                    .padding(.top, 8)
                                                    .padding(.trailing, 24)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .leading) {
                                    Button {
                                        person.isHidden.toggle()
                                    } label: {
                                        Label(person.isHidden ? "Unhide" : "Hide",
                                              systemImage: person.isHidden ? "eye" : "eye.slash")
                                    }
                                    .tint(AppColors.accentMid)
                                }
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
            .searchable(text: $searchText, prompt: "Search people")
            .toolbar {
                let hiddenCount = allPeople.filter { $0.isHidden }.count
                if hiddenCount > 0 {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showHidden.toggle()
                        } label: {
                            Label(
                                showHidden ? "Hide hidden" : "Show hidden (\(hiddenCount))",
                                systemImage: showHidden ? "eye.slash" : "eye"
                            )
                            .font(.system(size: 13))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditPersonView(onSaved: { toast = .success("Person added") })
            }
            .confirmationDialog(
                "Delete \(personToDelete?.name ?? "person")?",
                isPresented: Binding(get: { personToDelete != nil }, set: { if !$0 { personToDelete = nil } }),
                titleVisibility: .visible,
                presenting: personToDelete
            ) { person in
                Button("Delete", role: .destructive) {
                    let name = person.name
                    deletePerson(person)
                    personToDelete = nil
                    toast = .success("\(name) deleted")
                }
                Button("Cancel", role: .cancel) {
                    personToDelete = nil
                }
            } message: { person in
                Text("This removes \(person.name) and any birthday event tied to them.")
            }
            .toast(message: $toast)
        }
        .id(navState.resetCounters[.people])
        .onChange(of: navState.resetCounters[.people]) {
            showingAdd = false
            personToDelete = nil
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
                if !person.displayRelationshipLabel.isEmpty {
                    Text(person.displayRelationshipLabel)
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
