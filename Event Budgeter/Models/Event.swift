//
//  Event.swift
//  Event Budgeter
//

import Foundation
import SwiftData

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case birthday, anniversary, holiday, custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .birthday: "Birthday"
        case .anniversary: "Anniversary"
        case .holiday: "Holiday"
        case .custom: "Custom"
        }
    }

    var defaultEmoji: String {
        switch self {
        case .birthday: "🎂"
        case .anniversary: "💍"
        case .holiday: "🎄"
        case .custom: "⭐️"
        }
    }

    var color: String {
        switch self {
        case .birthday: "#FF6B6B"
        case .anniversary: "#C77DFF"
        case .holiday: "#4ECDC4"
        case .custom: "#FFD93D"
        }
    }
}

enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case yearly
    case none

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yearly: "Every Year"
        case .none: "One Time"
        }
    }
}

@Model
final class Event {
    var title: String
    var emoji: String
    var category: EventCategory
    var canonicalDate: Date
    var recurrenceRule: RecurrenceRule
    var notes: String
    var eventBudget: Decimal?
    var notifyOnDay: Bool = false
    var isHidden: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \EventPerson.event)
    var assignments: [EventPerson] = []

    init(
        title: String,
        emoji: String = "",
        category: EventCategory = .custom,
        canonicalDate: Date = .now,
        recurrenceRule: RecurrenceRule = .yearly,
        notes: String = ""
    ) {
        self.title = title
        self.emoji = emoji.isEmpty ? category.defaultEmoji : emoji
        self.category = category
        self.canonicalDate = canonicalDate
        self.recurrenceRule = recurrenceRule
        self.notes = notes
    }

    var displayEmoji: String {
        emoji.isEmpty ? category.defaultEmoji : emoji
    }

    var totalBudget: Decimal {
        assignments.reduce(0) { $0 + $1.budget }
    }

    var displayBudget: Decimal {
        eventBudget ?? totalBudget
    }

    var totalSpent: Decimal {
        assignments.flatMap { $0.purchases }.reduce(0) { $0 + $1.cost }
    }
}
