//
//  Color+Hex.swift
//  Event Budgeter
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension String {
    static let avatarColors = [
        "#5856D6", "#FF6B6B", "#4ECDC4", "#FFD93D",
        "#C77DFF", "#06D6A0", "#FB8500", "#E63946"
    ]

    static func randomAvatarColor() -> String {
        avatarColors.randomElement() ?? "#5856D6"
    }
}
