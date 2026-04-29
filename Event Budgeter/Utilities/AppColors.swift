//
//  AppColors.swift
//  Event Budgeter
//
//  Design system based on the GiftBudget soft-pastel oklch palette.
//

import SwiftUI

// MARK: - App-wide color tokens

enum AppColors {
    // Primary accent: soft purple/lavender (oklch 68% 0.16 290)
    static let accent        = Color(hex: "#8B5CF6").opacity(0.92)   // ~oklch(68% 0.16 290)
    static let accentSoft    = Color(hex: "#EDE9FE")                  // ~oklch(94% 0.04 290)
    static let accentMid     = Color(hex: "#C4B5FD")                  // ~oklch(78% 0.12 290)
    static let accentText    = Color(hex: "#5B21B6")                  // ~oklch(40% 0.14 290)

    // App background (oklch 96% 0.02 290)
    static let appBg         = Color(hex: "#F5F3F8")

    // Card background
    static let cardBg        = Color.white

    // Secondary text (oklch 55% 0.04 290)
    static let textSecondary = Color(hex: "#6B7280")
    // Tertiary text (oklch 65% 0.04 290)
    static let textTertiary  = Color(hex: "#9CA3AF")

    // Budget bar colors
    static let barGreen      = Color(hex: "#34D399")  // oklch(72% 0.14 160)
    static let barYellow     = Color(hex: "#FBBF24")  // oklch(78% 0.14 65)
    static let barRed        = Color(hex: "#F87171")  // oklch(72% 0.18 25)
    static let barBg         = Color(hex: "#EDE9FE")  // faint purple track

    // Status colors (gift pipeline)
    static let statusNeed    = Color(hex: "#F59E0B")  // need/idea - amber oklch(72% 0.14 65)
    static let statusNeedBg  = Color(hex: "#FEF3C7")
    static let statusHave    = Color(hex: "#3B82F6")  // tobuy - blue oklch(68% 0.14 220)
    static let statusHaveBg  = Color(hex: "#DBEAFE")
    static let statusWrap    = Color(hex: "#8B5CF6")  // wrapped - purple oklch(60% 0.16 290)
    static let statusWrapBg  = Color(hex: "#EDE9FE")
    static let statusGift    = Color(hex: "#10B981")  // given/gifted - green oklch(58% 0.12 140)
    static let statusGiftBg  = Color(hex: "#D1FAE5")

    // Tab bar
    static let tabActive     = Color(hex: "#5B21B6")  // oklch(40% 0.14 290)
    static let tabInactive   = Color(hex: "#9CA3AF")  // oklch(65% 0.04 290)
    static let tabBarBg      = Color.white.opacity(0.92)
    static let tabBarBorder  = Color(hex: "#E5E0EF")
}

// MARK: - Card modifier

struct BubbleCard: ViewModifier {
    var padding: EdgeInsets = .init(top: 14, leading: 14, bottom: 14, trailing: 14)
    var radius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    func bubbleCard(padding: EdgeInsets = .init(top: 14, leading: 14, bottom: 14, trailing: 14), radius: CGFloat = 16) -> some View {
        modifier(BubbleCard(padding: padding, radius: radius))
    }
}

// MARK: - Budget bar

struct BudgetProgressBar: View {
    let spent: Decimal
    let budget: Decimal
    let currency: String

    private var progress: Double {
        guard budget > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: spent / budget).doubleValue
        return min(ratio, 1.0)
    }
    private var isOver: Bool { budget > 0 && spent > budget }
    private var barColor: Color {
        isOver ? AppColors.barRed : progress >= 0.8 ? AppColors.barYellow : AppColors.barGreen
    }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.barBg).frame(height: 5)
                    Capsule().fill(barColor)
                        .frame(width: geo.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)

            HStack {
                Text("\(currency)\(NSDecimalNumber(decimal: spent).intValue) spent")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("\(currency)\(NSDecimalNumber(decimal: budget).intValue) budget")
                    .font(.system(size: 10))
                    .foregroundStyle(isOver ? AppColors.barRed : AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Days-until badge

struct DaysUntilBadge: View {
    let days: Int

    private var text: String {
        if days < 0 { return "\(abs(days))d ago" }
        if days == 0 { return "Today!" }
        return "\(days)d"
    }

    private var bgColor: Color {
        if days < 0 { return Color(hex: "#F3F4F6") }
        if days == 0 { return Color(hex: "#FEE2E2") }
        if days <= 7  { return Color(hex: "#FCE7F3") }
        if days <= 30 { return Color(hex: "#FEF3C7") }
        return AppColors.accentSoft
    }

    private var textColor: Color {
        if days < 0 { return AppColors.textTertiary }
        if days == 0 { return Color(hex: "#EF4444") }
        if days <= 7  { return Color(hex: "#BE185D") }
        if days <= 30 { return Color(hex: "#92400E") }
        return AppColors.accentText
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

// MARK: - Section header style

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}

extension View {
    func sectionHeaderStyle() -> some View {
        modifier(SectionHeaderStyle())
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? .white : AppColors.accentText)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(isActive ? AppColors.accent : AppColors.accentSoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAB

struct FABButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(AppColors.accent)
                .clipShape(Circle())
                .shadow(color: AppColors.accent.opacity(0.45), radius: 10, x: 0, y: 4)
        }
    }
}
