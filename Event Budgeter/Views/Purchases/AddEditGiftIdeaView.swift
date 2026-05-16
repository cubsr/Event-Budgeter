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

    private var isEditing: Bool { giftIdea != nil }

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
        } else {
            let idea = GiftIdea(
                name: trimmed,
                cost: cost,
                notes: notes,
                photoData: photoData,
                storeName: storeName,
                itemURL: itemURL
            )
            modelContext.insert(idea)
            onCreate?(idea)
        }
        onSaved?()
        dismiss()
    }
}
