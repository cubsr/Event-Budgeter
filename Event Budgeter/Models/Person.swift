//
//  Person.swift
//  Event Budgeter
//

import Foundation
import SwiftData

@Model
final class Person {
    var name: String
    var relationshipLabel: String
    var colorHex: String
    var photoData: Data?

    @Relationship(deleteRule: .cascade, inverse: \EventPerson.person)
    var assignments: [EventPerson] = []

    init(name: String, relationshipLabel: String = "", colorHex: String = "#5856D6") {
        self.name = name
        self.relationshipLabel = relationshipLabel
        self.colorHex = colorHex
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    func totalSpent(inYear year: Int) -> Decimal {
        let cal = Calendar.current
        return assignments
            .flatMap { $0.purchases }
            .filter { cal.component(.year, from: $0.purchaseDate) == year }
            .reduce(0) { $0 + $1.cost }
    }

    var totalSpentAllTime: Decimal {
        assignments.flatMap { $0.purchases }.reduce(0) { $0 + $1.cost }
    }
}
