//
//  AddEditGiftItemView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditGiftItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var giftItem: GiftItem?
    var initialStatus: ItemStatus = .idea
    var onCreate: ((GiftItem) -> Void)?

    @State private var name = ""
    @State private var costString = ""
    @State private var notes = ""
    @State private var status: ItemStatus = .idea
    @State private var storeName = ""
    @State private var itemURL = ""
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?

    private var isEditing: Bool { giftItem != nil }

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
                Section("Item") {
                    TextField("Name", text: $name)
                    HStack {
                        Text(Locale.current.currencySymbol ?? "$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $costString)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ItemStatus.allCases) { s in
                            Label(s.label, systemImage: s.icon).tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
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
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || cost < 0)
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
        guard let giftItem else {
            status = initialStatus
            return
        }
        name = giftItem.name
        costString = "\(giftItem.cost)"
        notes = giftItem.notes
        status = giftItem.status
        storeName = giftItem.storeName
        itemURL = giftItem.itemURL
        photoData = giftItem.photoData
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let giftItem {
            giftItem.name = trimmed
            giftItem.cost = cost
            giftItem.notes = notes
            giftItem.status = status
            giftItem.storeName = storeName
            giftItem.itemURL = itemURL
            giftItem.photoData = photoData
            dismiss()
        } else {
            let item = GiftItem(
                name: trimmed,
                cost: cost,
                notes: notes,
                status: status,
                photoData: photoData,
                storeName: storeName,
                itemURL: itemURL
            )
            modelContext.insert(item)
            onCreate?(item)
            dismiss()
        }
    }
}
