//
//  ItemStatus.swift
//  Event Budgeter
//

import SwiftUI

enum ItemStatus: String, Codable, CaseIterable, Identifiable {
    case need
    case have
    case wrap
    case gift

    var id: String { rawValue }

    var label: String {
        switch self {
        case .need: return "Need"
        case .have: return "Have"
        case .wrap: return "Wrapped"
        case .gift: return "Gifted"
        }
    }

    var icon: String {
        switch self {
        case .need: return "cart"
        case .have: return "checkmark.circle"
        case .wrap: return "shippingbox"
        case .gift: return "gift"
        }
    }

    var color: Color {
        switch self {
        case .need: return .orange
        case .have: return .blue
        case .wrap: return Color(hex: "#EC4899")
        case .gift: return .green
        }
    }
}
