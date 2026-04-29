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

    @State private var selectedPerson: Person?
    @State private var budgetString = ""
    @State private var showingNewPerson = false

    private var assignedPersonIDs: Set<PersistentIdentifier> {
        Set(event.assignments.compactMap { $0.person?.persistentModelID })
    }

    private var availablePeople: [Person] {
        allPeople.filter { !assignedPersonIDs.contains($0.persistentModelID) }
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
                                    Text("All people are already assigned.")
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
                                        selectedPerson = person
                                    } label: {
                                        HStack(spacing: 12) {
                                            PersonAvatarView(person: person, size: 34)

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(person.name)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(.primary)
                                                if !person.relationshipLabel.isEmpty {
                                                    Text(person.relationshipLabel)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(AppColors.textSecondary)
                                                }
                                            }

                                            Spacer()

                                            if selectedPerson?.persistentModelID == person.persistentModelID {
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
                                            selectedPerson?.persistentModelID == person.persistentModelID
                                                ? AppColors.accentSoft
                                                : AppColors.cardBg
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    selectedPerson?.persistentModelID == person.persistentModelID
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

                        // Budget input (only when person selected)
                        if selectedPerson != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Budget (Optional)")
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
                            }
                            .bubbleCard()
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle("Assign Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { assign() }
                        .foregroundStyle(AppColors.accent)
                        .fontWeight(.bold)
                        .disabled(selectedPerson == nil)
                }
            }
            .sheet(isPresented: $showingNewPerson) {
                AddEditPersonView()
            }
        }
    }

    private func assign() {
        guard let person = selectedPerson else { return }
        let ep = EventPerson(event: event, person: person, budget: budget)
        modelContext.insert(ep)
        event.assignments.append(ep)
        dismiss()
    }
}
