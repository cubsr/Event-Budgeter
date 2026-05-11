//
//  EditEventBudgetsSheet.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct EditEventBudgetsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var eventBudgetString = ""
    @State private var personBudgetStrings: [PersistentIdentifier: String] = [:]

    private var sortedAssignments: [EventPerson] {
        event.assignments
            .filter { $0.person != nil }
            .sorted { ($0.person?.name ?? "") < ($1.person?.name ?? "") }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("Use sum of per-person budgets", text: $eventBudgetString)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    Text("Event Total Override")
                } footer: {
                    Text("Leave blank to calculate total from individual budgets below.")
                }

                if !sortedAssignments.isEmpty {
                    Section("Per Person Budgets") {
                        ForEach(sortedAssignments) { ep in
                            if let person = ep.person {
                                HStack {
                                    PersonAvatarView(person: person, size: 28)
                                    Text(person.name)
                                    Spacer()
                                    Text(Locale.current.currencySymbol ?? "$")
                                        .foregroundStyle(.secondary)
                                    TextField("0.00", text: budgetBinding(for: ep))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
            .onAppear { load() }
        }
    }

    private func budgetBinding(for ep: EventPerson) -> Binding<String> {
        Binding(
            get: { personBudgetStrings[ep.persistentModelID] ?? "" },
            set: { personBudgetStrings[ep.persistentModelID] = $0 }
        )
    }

    private func load() {
        if let override = event.eventBudget {
            eventBudgetString = (override as NSDecimalNumber).stringValue
        }
        for ep in sortedAssignments {
            personBudgetStrings[ep.persistentModelID] = ep.budget > 0
                ? (ep.budget as NSDecimalNumber).stringValue
                : ""
        }
    }

    private func save() {
        let cleaned = eventBudgetString.replacingOccurrences(of: ",", with: ".")
        if let val = Decimal(string: cleaned), val > 0 {
            event.eventBudget = val
        } else {
            event.eventBudget = nil
        }
        for ep in sortedAssignments {
            let str = (personBudgetStrings[ep.persistentModelID] ?? "")
                .replacingOccurrences(of: ",", with: ".")
            ep.budget = Decimal(string: str) ?? 0
        }
        dismiss()
    }
}
