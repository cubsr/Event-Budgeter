//
//  YearSelectorView.swift
//  Event Budgeter
//
//  Shared infinite year selector: previous / selected / next capsule buttons.
//

import SwiftUI

struct YearSelectorView: View {
    @Binding var selectedYear: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach([selectedYear - 1, selectedYear, selectedYear + 1], id: \.self) { year in
                Button {
                    selectedYear = year
                } label: {
                    Text(String(year))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(selectedYear == year ? .white : AppColors.accentText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(selectedYear == year ? AppColors.accent : AppColors.accentSoft)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
