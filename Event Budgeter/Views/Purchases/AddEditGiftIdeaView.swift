//
//  AddEditGiftIdeaView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditGiftIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var giftIdea: GiftIdea?
    var onCreate: ((GiftIdea) -> Void)?
    var onSaved: (() -> Void)? = nil

    @State private var name = ""
    @State private var costString = ""
    @State private var notes = ""
    @State private var storeName = ""
    @State private var itemURL = ""
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPeople: Set<PersistentIdentifier> = []
    @State private var showingPeoplePicker = false

    @Query(sort: \Person.name) private var allPeople: [Person]

    private var isEditing: Bool { giftIdea != nil }

    private var chosenPeople: [Person] {
        allPeople.filter { selectedPeople.contains($0.persistentModelID) }
    }

    private var cost: Decimal {
        Decimal(string: costString.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var parsedURL: URL? {
        guard !itemURL.isEmpty else { return nil }
        let raw = itemURL.hasPrefix("http") ? itemURL : "https://\(itemURL)"
        return URL(string: raw)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Idea") {
                    TextField("Name", text: $name)
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("Typical cost (optional)", text: $costString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Details") {
                    TextField("Store / Source", text: $storeName)
                    HStack {
                        TextField("Link (URL)", text: $itemURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if let url = parsedURL {
                            Button {
                                openURL(url)
                            } label: {
                                Image(systemName: "safari").foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        showingPeoplePicker = true
                    } label: {
                        HStack {
                            Text("Choose People")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(chosenPeople.isEmpty ? "Anyone" : "\(chosenPeople.count) selected")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    if !chosenPeople.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(chosenPeople) { person in
                                    HStack(spacing: 6) {
                                        PersonAvatarView(person: person, size: 22)
                                        Text(person.name)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(AppColors.accentSoft)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                } header: {
                    Text("For (optional)")
                } footer: {
                    Text("Ideas show up first for the people you choose here.")
                }

                Section("Photo") {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        HStack {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            Spacer()
                            Button("Remove", role: .destructive) {
                                self.photoData = nil
                                selectedPhotoItem = nil
                            }
                        }
                    }
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo.badge.plus")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Idea" : "New Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || cost < 0)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
                }
            }
            .sheet(isPresented: $showingPeoplePicker) {
                PersonMultiSelectSheet(selected: $selectedPeople)
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
        guard let giftIdea else { return }
        name = giftIdea.name
        costString = giftIdea.cost > 0 ? (giftIdea.cost as NSDecimalNumber).stringValue : ""
        notes = giftIdea.notes
        storeName = giftIdea.storeName
        itemURL = giftIdea.itemURL
        photoData = giftIdea.photoData
        selectedPeople = Set(giftIdea.people.map { $0.persistentModelID })
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let giftIdea {
            giftIdea.name = trimmed
            giftIdea.cost = cost
            giftIdea.notes = notes
            giftIdea.storeName = storeName
            giftIdea.itemURL = itemURL
            giftIdea.photoData = photoData
            giftIdea.people = chosenPeople
        } else {
            let idea = GiftIdea(
                name: trimmed,
                cost: cost,
                notes: notes,
                photoData: photoData,
                storeName: storeName,
                itemURL: itemURL,
                people: chosenPeople
            )
            modelContext.insert(idea)
            onCreate?(idea)
        }
        onSaved?()
        dismiss()
    }
}

// MARK: - Person Multi-Select

struct PersonMultiSelectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selected: Set<PersistentIdentifier>

    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var searchText = ""

    private var people: [Person] {
        let visible = allPeople.filter { !$0.isHidden }
        if searchText.isEmpty { return visible }
        return visible.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                if people.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No People Yet" : "No Results",
                        systemImage: "person.2",
                        description: Text(searchText.isEmpty
                            ? "Add people first to assign ideas to them."
                            : "No people match \"\(searchText)\".")
                    )
                } else {
                    ForEach(people) { person in
                        let isSelected = selected.contains(person.persistentModelID)
                        Button {
                            if isSelected {
                                selected.remove(person.persistentModelID)
                            } else {
                                selected.insert(person.persistentModelID)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                PersonAvatarView(person: person, size: 34)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    if !person.displayRelationshipLabel.isEmpty {
                                        Text(person.displayRelationshipLabel)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppColors.accent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search people")
            .navigationTitle("Choose People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
