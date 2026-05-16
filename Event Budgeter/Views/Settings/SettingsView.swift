//
//  SettingsView.swift
//  Event Budgeter
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    Button {
                        // Deep-links to this app's notification page in Settings.
                        // Note: only works on a physical device — the iOS Simulator
                        // ignores Settings subpage deep links and falls back to root.
                        let urlString = UIApplication.openNotificationSettingsURLString
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Notification Settings", systemImage: "bell.badge")
                            .foregroundStyle(.primary)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
