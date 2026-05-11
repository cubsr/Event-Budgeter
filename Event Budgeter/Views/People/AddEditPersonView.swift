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

    var person: Person?

    @State private var name = ""
    @State private var relationshipLabel = ""
    @State private var colorHex = String.randomAvatarColor()
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var addBirthday = false
    @State private var birthday: Date = {
        // Default to today but year-only feels natural — we'll use .now
        Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? .now
    }()

    private var isEditing: Bool { person != nil }

    private var existingBirthdayEvent: Event? {
        person?.assignments.first(where: { $0.event?.category == .birthday })?.event
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Full name", text: $name)
                }

                Section("Relationship") {
                    TextField("e.g. Mom, Spouse, Friend", text: $relationshipLabel)
                }

                Section {
                    if let existing = existingBirthdayEvent {
                        HStack {
                            Label("Birthday already added", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(existing.canonicalDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
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
                            if !relationshipLabel.isEmpty {
                                Text(relationshipLabel)
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
        }
    }

    private func populate() {
        guard let person else { return }
        name = person.name
        relationshipLabel = person.relationshipLabel
        colorHex = person.colorHex
        photoData = person.photoData
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let person {
            person.name = trimmed
            person.relationshipLabel = relationshipLabel
            person.colorHex = colorHex
            person.photoData = photoData
            if addBirthday && existingBirthdayEvent == nil {
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
        } else {
            let p = Person(name: trimmed, relationshipLabel: relationshipLabel, colorHex: colorHex)
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
        }
        dismiss()
    }
}
