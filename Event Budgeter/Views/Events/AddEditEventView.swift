//
//  AddEditEventView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var event: Event?

    @State private var title = ""
    @State private var emoji = ""
    @State private var category: EventCategory = .custom
    @State private var canonicalDate: Date = .now
    @State private var recurrenceRule: RecurrenceRule = .yearly
    @State private var notes = ""
    @State private var notifyOnDay = false
    @State private var notificationPermissionDenied = false

    private var isEditing: Bool { event != nil }

    // Birthdays are created from a Person's birthday field, never standalone.
    // Existing birthday events keep .birthday available in the picker so we don't change their category on edit.
    private var pickerCategories: [EventCategory] {
        if event?.category == .birthday {
            return EventCategory.allCases
        }
        return EventCategory.allCases.filter { $0 != .birthday }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // Event Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Event Details")
                                .sectionHeaderStyle()

                            TextField("Event title", text: $title)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(AppColors.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            HStack(spacing: 10) {
                                TextField("😀", text: $emoji)
                                    .font(.system(size: 28))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 56, height: 52)
                                    .background(AppColors.accentSoft)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                Picker("Category", selection: $category) {
                                    ForEach(pickerCategories) { cat in
                                        Text(cat.label).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .background(AppColors.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onChange(of: category) { _, newCat in
                                    if emoji.isEmpty || EventCategory.allCases.map(\.defaultEmoji).contains(emoji) {
                                        emoji = newCat.defaultEmoji
                                    }
                                }
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)

                        // Date
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date")
                                .sectionHeaderStyle()

                            DatePicker(
                                recurrenceRule == .yearly ? "Day & Month" : "Date",
                                selection: $canonicalDate,
                                displayedComponents: [.date]
                            )
                            .font(.system(size: 15))

                            HStack {
                                Text("Repeats")
                                    .font(.system(size: 15))
                                    .foregroundStyle(AppColors.textSecondary)
                                Spacer()
                                Picker("Repeats", selection: $recurrenceRule) {
                                    ForEach(RecurrenceRule.allCases) { rule in
                                        Text(rule.label).tag(rule)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)

                        // Notes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .sectionHeaderStyle()

                            TextField("Optional notes", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(AppColors.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)

                        // Notifications
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notifications")
                                .sectionHeaderStyle()

                            Toggle("Notify on event day", isOn: $notifyOnDay)
                                .font(.system(size: 15))
                                .onChange(of: notifyOnDay) { _, enabled in
                                    if enabled {
                                        NotificationManager.requestPermission { granted in
                                            if !granted {
                                                notifyOnDay = false
                                                notificationPermissionDenied = true
                                            }
                                        }
                                    }
                                }

                            if notificationPermissionDenied {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.slash")
                                        .foregroundStyle(.orange)
                                    Text("Notifications are disabled. Enable them in Settings.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Settings") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(AppColors.accent)
                                }
                                .padding(10)
                                .background(Color.orange.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .bubbleCard()
                        .padding(.horizontal, 16)

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 14)
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.accent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
        }
    }

    private func populate() {
        guard let event else {
            emoji = category.defaultEmoji
            return
        }
        title = event.title
        emoji = event.emoji
        category = event.category
        canonicalDate = event.canonicalDate
        recurrenceRule = event.recurrenceRule
        notes = event.notes
        notifyOnDay = event.notifyOnDay
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let finalEmoji = emoji.isEmpty ? category.defaultEmoji : emoji
        if let event {
            event.title = trimmed
            event.emoji = finalEmoji
            event.category = category
            event.canonicalDate = canonicalDate
            event.recurrenceRule = recurrenceRule
            event.notes = notes
            event.notifyOnDay = notifyOnDay
            NotificationManager.cancelNotification(for: event)
            NotificationManager.scheduleEventNotification(for: event)
        } else {
            let e = Event(
                title: trimmed,
                emoji: finalEmoji,
                category: category,
                canonicalDate: canonicalDate,
                recurrenceRule: recurrenceRule,
                notes: notes
            )
            e.notifyOnDay = notifyOnDay
            modelContext.insert(e)
            NotificationManager.scheduleEventNotification(for: e)
        }
        dismiss()
    }
}
