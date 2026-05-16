//
//  StandardRelationship.swift
//  Event Budgeter
//

import Foundation

enum StandardRelationship: String, Codable, CaseIterable, Identifiable {
    case mom, dad, grandma, grandpa, spouse, sibling, child, friend, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mom:     "Mom"
        case .dad:     "Dad"
        case .grandma: "Grandma"
        case .grandpa: "Grandpa"
        case .spouse:  "Spouse"
        case .sibling: "Sibling"
        case .child:   "Child"
        case .friend:  "Friend"
        case .other:   "Other"
        }
    }

    var emoji: String {
        switch self {
        case .mom:     "👩"
        case .dad:     "👨"
        case .grandma: "👵"
        case .grandpa: "👴"
        case .spouse:  "💑"
        case .sibling: "🧑"
        case .child:   "👶"
        case .friend:  "🤝"
        case .other:   "⭐️"
        }
    }

    // Returns the systemKey of the holiday this relationship auto-assigns to, or nil.
    var holidaySystemKey: String? {
        switch self {
        case .mom: return "holiday.mothers_day"
        case .dad: return "holiday.fathers_day"
        default:   return nil
        }
    }
}
