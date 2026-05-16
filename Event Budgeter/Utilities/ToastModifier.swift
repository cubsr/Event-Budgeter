//
//  ToastModifier.swift
//  Event Budgeter
//

import SwiftUI

// MARK: - Toast message value type

struct ToastMessage: Equatable {
    enum Style { case success, error }
    let text: String
    let style: Style

    static func success(_ text: String) -> ToastMessage { .init(text: text, style: .success) }
    static func error(_ text: String)   -> ToastMessage { .init(text: text, style: .error) }
}

// MARK: - Modifier

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastMessage?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let t = toast {
                    ToastBanner(message: t)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeOut(duration: 0.25)) { toast = nil }
                            }
                        }
                        .padding(.bottom, 100)
                }
            }
            .animation(.spring(duration: 0.35), value: toast)
    }
}

extension View {
    func toast(message: Binding<ToastMessage?>) -> some View {
        modifier(ToastModifier(toast: message))
    }
}

// MARK: - Banner view

private struct ToastBanner: View {
    let message: ToastMessage

    private var iconName: String {
        message.style == .success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private var iconColor: Color {
        message.style == .success ? AppColors.barGreen : AppColors.barRed
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(message.text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppColors.cardBg)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 3)
    }
}
