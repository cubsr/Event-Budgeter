//
//  EventPerson.swift
//  Event Budgeter
//

import Foundation
import SwiftData

@Model
final class EventPerson {
    var budget: Decimal
    var notes: String

    var event: Event?
    var person: Person?

    @Relationship(deleteRule: .cascade, inverse: \PurchaseItem.eventPerson)
    var purchases: [PurchaseItem] = []

    var giftItems: [GiftItem] = []

    init(event: Event, person: Person, budget: Decimal = 0, notes: String = "") {
        self.event = event
        self.person = person
        self.budget = budget
        self.notes = notes
    }

    var totalSpent: Decimal {
        purchases.reduce(0) { $0 + $1.cost }
    }

    var remainingBudget: Decimal {
        budget - totalSpent
    }

    var isOverBudget: Bool {
        budget > 0 && totalSpent > budget
    }

    var spendProgress: Double {
        guard budget > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: totalSpent / budget).doubleValue
        return min(ratio, 1.0)
    }

    var giftedCount: Int {
        purchases.filter { $0.status == .gift }.count
    }
}
