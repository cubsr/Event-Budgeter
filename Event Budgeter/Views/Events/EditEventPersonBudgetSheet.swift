//
//  EditEventPersonBudgetSheet.swift
//  Event Budgeter
//

import SwiftUI

struct EditEventPersonBudgetSheet: View {
    @Environment(\.dismiss) private var dismiss

    let eventPerson: EventPerson

    @State private var budgetString = ""

    private var budget: Decimal {
        Decimal(string: budgetString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $budgetString)
                            .keyboardType(.decimalPad)
                    }
                } header: {
                    if let person = eventPerson.person {
                        Text("Budget for \(person.name)")
                    }
                }
            }
            .navigationTitle("Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        eventPerson.budget = budget
                        dismiss()
                    }
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
            .onAppear {
                if eventPerson.budget > 0 {
                    budgetString = "\(eventPerson.budget)"
                }
            }
        }
    }
}
