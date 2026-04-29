//
//  ItemStatus.swift
//  Event Budgeter
//

import SwiftUI

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case idea
    case need
    case have
    case wrap
    case gift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .idea: return "Idea"
        case .need: return "Need"
        case .have: return "Have"
        case .wrap: return "Wrap"
        case .gift: return "Gift"
        }
    }

    var icon: String {
        switch self {
        case .idea: return "lightbulb"
        case .need: return "cart"
        case .have: return "checkmark.circle"
        case .wrap: return "shippingbox"
        case .gift: return "gift"
        }
    }

    var color: Color {
        switch self {
        case .idea: return Color(hex: "#A78BFA")   // violet
        case .need: return .orange
        case .have: return .blue
        case .wrap: return Color(hex: "#EC4899")   // pink
        case .gift: return .green
        }
    }
}
