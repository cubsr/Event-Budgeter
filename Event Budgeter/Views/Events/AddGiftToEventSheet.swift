//
//  AddGiftToEventSheet.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct AddGiftToEventSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @Query(sort: \Person.name) private var allPeople: [Person]

    @State private var selectedEventPerson: EventPerson?
    @State private var showingIdeaPicker = false
    @State private var showingNewPerson = false
    @State private var giftAdded = false
    @State private var initialGiftCount = 0

    private var currentGiftCount: Int {
        event.assignments.flatMap { $0.purchases }.count
    }

    private var sortedAssignments: [EventPerson] {
        event.assignments.compactMap { $0.person != nil ? $0 : nil }
            .sorted { ($0.person?.name ?? "") < ($1.person?.name ?? "") }
    }

    private var assignedPersonIDs: Set<PersistentIdentifier> {
        Set(event.assignments.compactMap { $0.person?.persistentModelID })
    }

    private var unassignedPeople: [Person] {
        allPeople.filter { !assignedPersonIDs.contains($0.persistentModelID) && !$0.isHidden }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Person picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("For who?")
                                .sectionHeaderStyle()

                            if sortedAssignments.isEmpty && allPeople.isEmpty {
                                VStack(spacing: 8) {
                                    Text("No people yet.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColors.textSecondary)
                                    Button("Create New Person") { showingNewPerson = true }
                                        .foregroundStyle(AppColors.accent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            } else {
                                // Already on this event
                                if !sortedAssignments.isEmpty {
                                    ForEach(sortedAssignments) { ep in
                                        if let person = ep.person {
                                            personRow(person: person, isSelected: selectedEventPerson?.persistentModelID == ep.persistentModelID) {
                                                selectedEventPerson = ep
                                            }
                                        }
                                    }
                                }

                                // People not yet on event
                                if !unassignedPeople.isEmpty {
                                    if !sortedAssignments.isEmpty {
                                        HStack {
                                            Text("Add to event")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(AppColors.textSecondary)
                                                .textCase(.uppercase)
                                            Rectangle()
                                                .fill(AppColors.accentSoft)
                                                .frame(height: 1)
                                        }
                                        .padding(.top, 4)
                                    }

                                    ForEach(unassignedPeople) { person in
                                        let isSelected = selectedEventPerson?.person?.persistentModelID == person.persistentModelID
                                        personRow(person: person, isSelected: isSelected) {
                                            assignAndSelect(person: person)
                                        }
                                    }
                                }

                                Button {
                                    showingNewPerson = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppColors.accent)
                                        Text("Create New Person")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(AppColors.accent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)

                        // Action (shown once a person is selected)
                        if selectedEventPerson != nil {
                            Button {
                                showingIdeaPicker = true
                            } label: {
                                Label("Add Gift", systemImage: "gift")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.accent)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Add Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(giftAdded ? "Done" : "Cancel") { dismiss() }
                }
            }
            .onAppear {
                initialGiftCount = currentGiftCount
            }
            .sheet(isPresented: $showingNewPerson) {
                AddEditPersonView()
            }
            .sheet(isPresented: $showingIdeaPicker, onDismiss: {
                if currentGiftCount > initialGiftCount {
                    giftAdded = true
                }
            }) {
                if let ep = selectedEventPerson {
                    GiftIdeaPickerSheet(eventPerson: ep, onGiftSaved: { dismiss() })
                }
            }
        }
    }

    @ViewBuilder
    private func personRow(person: Person, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                PersonAvatarView(person: person, size: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    if !person.displayRelationshipLabel.isEmpty {
                        Text(person.displayRelationshipLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.accent)
                } else {
                    Circle()
                        .strokeBorder(AppColors.accentMid, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(12)
            .background(isSelected ? AppColors.accentSoft : AppColors.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AppColors.accentMid : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func assignAndSelect(person: Person) {
        // Check if we somehow already have an EventPerson for this person (race condition guard)
        if let existing = event.assignments.first(where: { $0.person?.persistentModelID == person.persistentModelID }) {
            selectedEventPerson = existing
            return
        }
        let ep = EventPerson(event: event, person: person, budget: 0)
        modelContext.insert(ep)
        event.assignments.append(ep)
        selectedEventPerson = ep
    }
}
