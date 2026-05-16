//
//  AddEditPurchaseView.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditPurchaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let eventPerson: EventPerson
    var purchase: PurchaseItem?
    var prefill: GiftIdea? = nil
    var onSave: (() -> Void)? = nil

    @State private var name = ""
    @State private var costString = ""
    @State private var notes = ""
    @State private var purchaseDate: Date = .now
    @State private var status: ItemStatus = .need
    @State private var storeName = ""
    @State private var itemURL = ""
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var saveAsIdea: Bool = true

    private var isEditing: Bool { purchase != nil }

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
                            Label(s.label, systemImage: s.icon)
                                .tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 2)
                }

                Section("Details") {
                    DatePicker("Date", selection: $purchaseDate, displayedComponents: .date)
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
                                Image(systemName: "safari")
                                    .foregroundStyle(.blue)
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

                if let ep = purchase?.eventPerson,
                   let person = ep.person,
                   let event = ep.event {
                    Section("For") {
                        Label("\(person.name) · \(event.title)", systemImage: "person")
                            .foregroundStyle(.secondary)
                    }
                }

                if !isEditing && prefill == nil {
                    Section {
                        Toggle("Also save as a reusable idea", isOn: $saveAsIdea)
                    } footer: {
                        Text("Saved ideas show up in the Ideas tab and can be reused for other gifts.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
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
        if let purchase {
            name = purchase.name
            costString = purchase.cost > 0 ? (purchase.cost as NSDecimalNumber).stringValue : ""
            notes = purchase.notes
            purchaseDate = purchase.purchaseDate
            status = purchase.status
            storeName = purchase.storeName
            itemURL = purchase.itemURL
            photoData = purchase.photoData
        } else if let prefill {
            name = prefill.name
            // Cash Gift always gets a blank cost so the user enters the specific amount
            costString = prefill.isCashGift ? "" : (prefill.cost > 0 ? (prefill.cost as NSDecimalNumber).stringValue : "")
            notes = prefill.notes
            storeName = prefill.storeName
            itemURL = prefill.itemURL
            photoData = prefill.photoData
            // Already pulled from an idea — don't re-create one
            saveAsIdea = false
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let purchase {
            purchase.name = trimmed
            purchase.cost = cost
            purchase.notes = notes
            purchase.purchaseDate = purchaseDate
            purchase.status = status
            purchase.storeName = storeName
            purchase.itemURL = itemURL
            purchase.photoData = photoData
        } else {
            let item = PurchaseItem(
                name: trimmed,
                cost: cost,
                notes: notes,
                purchaseDate: purchaseDate,
                status: status,
                photoData: photoData,
                storeName: storeName,
                itemURL: itemURL,
                eventPerson: eventPerson
            )
            modelContext.insert(item)
            eventPerson.purchases.append(item)

            if saveAsIdea {
                let idea = GiftIdea(
                    name: trimmed,
                    cost: cost,
                    notes: notes,
                    photoData: photoData,
                    storeName: storeName,
                    itemURL: itemURL
                )
                modelContext.insert(idea)
            }
        }
        onSave?()
        dismiss()
    }
}
