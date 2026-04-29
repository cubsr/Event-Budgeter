//
//  CalendarDayCell.swift
//  Event Budgeter
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let events: [Event]
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(dayNumber)
                .font(.system(size: 13, weight: isToday ? .bold : .regular))
                .foregroundStyle(numberColor)
                .frame(width: 28, height: 28)
                .background {
                    if isSelected {
                        Circle().fill(AppColors.accent)
                    } else if isToday {
                        Circle().fill(AppColors.accentSoft)
                    }
                }

            // Event dots
            HStack(spacing: 2) {
                ForEach(events.prefix(3).map { $0.category }, id: \.self) { cat in
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.8) : Color(hex: cat.color))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .opacity(isCurrentMonth ? 1 : 0.3)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var numberColor: Color {
        if isSelected { return .white }
        if isToday { return AppColors.accentText }
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { return Color(hex: "#EF4444").opacity(isCurrentMonth ? 0.85 : 0.4) }
        return isCurrentMonth ? .primary : .secondary
    }
}
