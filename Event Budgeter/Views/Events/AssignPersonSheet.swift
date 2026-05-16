//
//  AssignPersonSheet.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct AssignPersonSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event
    @Query(sort: \Person.name) private var allPeople: [Person]

    @State private var selectedPersonIDs: Set<PersistentIdentifier> = []
    @State private var searchText = ""
    @State private var budgetString = ""
    @State private var showingNewPerson = false

    private var assignedPersonIDs: Set<PersistentIdentifier> {
        Set(event.assignments.compactMap { $0.person?.persistentModelID })
    }

    private var availablePeople: [Person] {
        let base = allPeople.filter {
            !assignedPersonIDs.contains($0.persistentModelID) && !$0.isHidden
        }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.displayRelationshipLabel.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var selectedPeople: [Person] {
        allPeople.filter { selectedPersonIDs.contains($0.persistentModelID) }
    }

    private var budget: Decimal {
        Decimal(string: budgetString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // People picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select Person")
                                .sectionHeaderStyle()

                            if availablePeople.isEmpty {
                                VStack(spacing: 8) {
                                    Text(searchText.isEmpty
                                         ? "All people are already assigned."
                                         : "No matching people.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(AppColors.textSecondary)
                                    Button("Create New Person") { showingNewPerson = true }
                                        .foregroundStyle(AppColors.accent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            } else {
                                ForEach(availablePeople) { person in
                                    Button {
                                        if selectedPersonIDs.contains(person.persistentModelID) {
                                            selectedPersonIDs.remove(person.persistentModelID)
                                        } else {
                                            selectedPersonIDs.insert(person.persistentModelID)
                                        }
                                    } label: {
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

                                            if selectedPersonIDs.contains(person.persistentModelID) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(AppColors.accent)
                                            } else {
                                                Circle()
                                                    .strokeBorder(AppColors.accentMid, lineWidth: 1.5)
                                                    .frame(width: 22, height: 22)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            selectedPersonIDs.contains(person.persistentModelID)
                                                ? AppColors.accentSoft
                                                : AppColors.cardBg
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    selectedPersonIDs.contains(person.persistentModelID)
                                                        ? AppColors.accentMid
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
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

                        // Budget input (only when at least one person selected)
                        if !selectedPersonIDs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Budget per person (Optional)")
                                    .sectionHeaderStyle()

                                HStack(spacing: 8) {
                                    Text("$")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(AppColors.textSecondary)
                                    TextField("0.00", text: $budgetString)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 22, weight: .bold))
                                }
                                .padding(12)
                                .background(AppColors.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Text("Applied to each selected person.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .bubbleCard()
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Assign People")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search people")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selectedPersonIDs.isEmpty ? "Add" : "Add (\(selectedPersonIDs.count))") {
                        assign()
                    }
                        .foregroundStyle(AppColors.accent)
                        .fontWeight(.bold)
                        .disabled(selectedPersonIDs.isEmpty)
                }
            }
            .sheet(isPresented: $showingNewPerson) {
                AddEditPersonView()
            }
        }
    }

    private func assign() {
        for person in selectedPeople {
            let ep = EventPerson(event: event, person: person, budget: budget)
            modelContext.insert(ep)
            event.assignments.append(ep)
        }
        dismiss()
    }
}
