//
//  AddEditPersonView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allEvents: [Event]

    var person: Person?
    var onSaved: (() -> Void)? = nil

    @State private var name = ""
    @State private var standardRelationship: StandardRelationship = .other
    @State private var customRelationshipLabel = ""
    @State private var colorHex = String.randomAvatarColor()
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var addBirthday = false
    @State private var birthday: Date = {
        Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? .now
    }()
    @State private var pendingBirthdayRemoval = false
    @State private var showingRemoveBirthdayConfirm = false

    private var isEditing: Bool { person != nil }

    private var existingBirthdayEvent: Event? {
        person?.assignments.first(where: { $0.event?.category == .birthday })?.event
    }

    private var previewRelationshipLabel: String {
        standardRelationship == .other ? customRelationshipLabel : standardRelationship.label
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Full name", text: $name)
                }

                Section("Relationship") {
                    Picker("Type", selection: $standardRelationship) {
                        ForEach(StandardRelationship.allCases) { rel in
                            Text(rel.label).tag(rel)
                        }
                    }
                    if standardRelationship == .other {
                        TextField("Custom relationship (optional)", text: $customRelationshipLabel)
                    }
                }

                Section {
                    if existingBirthdayEvent != nil && !pendingBirthdayRemoval {
                        DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                        Button(role: .destructive) {
                            showingRemoveBirthdayConfirm = true
                        } label: {
                            Label("Remove Birthday", systemImage: "trash")
                        }
                    } else if pendingBirthdayRemoval {
                        HStack {
                            Label("Birthday will be removed on Save", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Spacer()
                            Button("Undo") { pendingBirthdayRemoval = false }
                                .foregroundStyle(AppColors.accent)
                        }
                    } else {
                        Toggle("Add Birthday", isOn: $addBirthday)
                        if addBirthday {
                            DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                        }
                    }
                } header: {
                    Text("Birthday")
                } footer: {
                    if existingBirthdayEvent == nil && addBirthday {
                        Text("A recurring birthday event will be created and \(name.isEmpty ? "this person" : name) will be added to it.")
                    } else if pendingBirthdayRemoval {
                        Text("The birthday event and its tracked gifts will be permanently deleted.")
                    }
                }

                Section("Photo") {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            Spacer()
                            Button("Remove Photo", role: .destructive) {
                                self.photoData = nil
                                selectedPhotoItem = nil
                            }
                        }
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "person.crop.circle.badge.plus")
                    }
                }

                Section("Avatar Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(String.avatarColors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    if colorHex == hex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .fontWeight(.bold)
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        if let photoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 44, height: 44)
                                .overlay {
                                    Text(name.isEmpty ? "?" : String(name.prefix(2).uppercased()))
                                        .foregroundStyle(.white)
                                        .fontWeight(.semibold)
                                        .font(.subheadline)
                                }
                        }
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Name" : name)
                                .fontWeight(.medium)
                            if !previewRelationshipLabel.isEmpty {
                                Text(previewRelationshipLabel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Preview")
                }
            }
            .navigationTitle(isEditing ? "Edit Person" : "New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { populate() }
            .onChange(of: selectedPhotoItem) {
                Task {
                    if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .confirmationDialog(
                "Remove this birthday?",
                isPresented: $showingRemoveBirthdayConfirm,
                titleVisibility: .visible
            ) {
                Button("Remove Birthday", role: .destructive) {
                    pendingBirthdayRemoval = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The birthday event and any gifts tracked for it will be deleted when you tap Save.")
            }
        }
    }

    private func populate() {
        guard let person else { return }
        name = person.name
        if let rel = person.standardRelationship {
            standardRelationship = rel
            customRelationshipLabel = person.customRelationshipLabel
        } else {
            // Legacy record: show as "Other" with existing text in the custom field
            standardRelationship = .other
            customRelationshipLabel = person.relationshipLabel
        }
        colorHex = person.colorHex
        photoData = person.photoData
        if let existing = existingBirthdayEvent {
            birthday = existing.canonicalDate
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let displayLabel = standardRelationship == .other ? customRelationshipLabel : standardRelationship.label

        if let person {
            person.name = trimmed
            person.standardRelationship = standardRelationship
            person.customRelationshipLabel = customRelationshipLabel
            person.relationshipLabel = displayLabel
            person.colorHex = colorHex
            person.photoData = photoData

            if let existing = existingBirthdayEvent {
                if pendingBirthdayRemoval {
                    NotificationManager.cancelNotification(for: existing)
                    modelContext.delete(existing)
                } else {
                    existing.canonicalDate = birthday
                    existing.title = "\(trimmed)'s Birthday"
                    NotificationManager.cancelNotification(for: existing)
                    NotificationManager.scheduleEventNotification(for: existing)
                }
            } else if addBirthday {
                let event = Event(
                    title: "\(trimmed)'s Birthday",
                    emoji: "🎂",
                    category: .birthday,
                    canonicalDate: birthday,
                    recurrenceRule: .yearly
                )
                modelContext.insert(event)
                let ep = EventPerson(event: event, person: person)
                modelContext.insert(ep)
            }

            autoAssignHolidays(person: person)
        } else {
            let p = Person(
                name: trimmed,
                relationshipLabel: displayLabel,
                colorHex: colorHex,
                standardRelationship: standardRelationship,
                customRelationshipLabel: customRelationshipLabel
            )
            p.photoData = photoData
            modelContext.insert(p)
            if addBirthday {
                let event = Event(
                    title: "\(trimmed)'s Birthday",
                    emoji: "🎂",
                    category: .birthday,
                    canonicalDate: birthday,
                    recurrenceRule: .yearly
                )
                modelContext.insert(event)
                let ep = EventPerson(event: event, person: p)
                modelContext.insert(ep)
            }
            autoAssignHolidays(person: p)
        }
        onSaved?()
        dismiss()
    }

    private func autoAssignHolidays(person: Person) {
        guard let holidayKey = standardRelationship.holidaySystemKey,
              let holiday = allEvents.first(where: { $0.systemKey == holidayKey })
        else { return }

        let alreadyAssigned = holiday.assignments.contains {
            $0.person?.persistentModelID == person.persistentModelID
        }
        guard !alreadyAssigned else { return }

        let ep = EventPerson(event: holiday, person: person)
        modelContext.insert(ep)
    }
}
