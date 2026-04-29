//
//  GiftItemPickerSheet.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct GiftItemPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let eventPerson: EventPerson
    @Query(sort: \GiftItem.name) private var allTemplates: [GiftItem]

    @State private var searchText = ""
    @State private var showingNewTemplate = false

    private var filteredTemplates: [GiftItem] {
        if searchText.isEmpty { return allTemplates }
        return allTemplates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingNewTemplate = true
                    } label: {
                        Label("Create New Template", systemImage: "plus.circle")
                    }
                }

                if filteredTemplates.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Templates Yet" : "No Results",
                        systemImage: "square.stack",
                        description: Text(searchText.isEmpty
                            ? "Create a template to reuse the same item for multiple people."
                            : "No templates match \"\(searchText)\".")
                    )
                } else {
                    Section("Templates") {
                        ForEach(filteredTemplates) { template in
                            Button {
                                addTemplate(template)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        HStack(spacing: 4) {
                                            Image(systemName: template.status.icon)
                                                .font(.caption)
                                                .foregroundStyle(template.status.color)
                                            Text(template.status.label)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if !template.storeName.isEmpty {
                                                Text("· \(template.storeName)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                    Spacer()
                                    if template.cost > 0 {
                                        Text(template.cost.currencyFormatted)
                                            .foregroundStyle(.secondary)
                                    }
                                    if eventPerson.giftItems.contains(where: { $0.persistentModelID == template.persistentModelID }) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search templates")
            .navigationTitle("Add from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewTemplate) {
                AddEditGiftItemView { newItem in
                    modelContext.insert(newItem)
                    eventPerson.giftItems.append(newItem)
                    newItem.assignments.append(eventPerson)
                }
            }
        }
    }

    private func addTemplate(_ template: GiftItem) {
        guard !eventPerson.giftItems.contains(where: { $0.persistentModelID == template.persistentModelID }) else { return }
        eventPerson.giftItems.append(template)
        template.assignments.append(eventPerson)
    }
}
