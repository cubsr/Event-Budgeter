//
//  GiftIdeaPickerSheet.swift
//  Event Budgeter
//

import SwiftUI
import SwiftData

struct GiftIdeaPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let eventPerson: EventPerson
    @Query(sort: \GiftIdea.name) private var allIdeas: [GiftIdea]

    @State private var searchText = ""
    @State private var showingNewIdea = false
    @State private var selectedIdea: GiftIdea?
    @State private var editingIdea: GiftIdea?
    @State private var ideaToDelete: GiftIdea?

    private var cashGiftIdea: GiftIdea? {
        allIdeas.first { $0.isCashGift }
    }

    private var regularIdeas: [GiftIdea] {
        let items = allIdeas.filter { !$0.isCashGift }
        if searchText.isEmpty { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Cash Gift — always at the top
                if let cashGift = cashGiftIdea {
                    Section {
                        Button {
                            selectedIdea = cashGift
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.green.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Text("💵")
                                        .font(.system(size: 18))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Cash Gift")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text("Enter the amount each time")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        showingNewIdea = true
                    } label: {
                        Label("Create New Idea", systemImage: "lightbulb")
                    }
                }

                if regularIdeas.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "lightbulb",
                        description: Text("No ideas match \"\(searchText)\".")
                    )
                } else if regularIdeas.isEmpty {
                    ContentUnavailableView(
                        "No Ideas Yet",
                        systemImage: "lightbulb",
                        description: Text("Save ideas here to reuse them when buying gifts.")
                    )
                } else {
                    Section("Ideas") {
                        ForEach(regularIdeas) { idea in
                            Button {
                                selectedIdea = idea
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(idea.name)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        if !idea.storeName.isEmpty {
                                            Text(idea.storeName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if idea.cost > 0 {
                                        Text(idea.cost.currencyFormatted)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingIdea = idea
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(AppColors.accent)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    ideaToDelete = idea
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search ideas")
            .navigationTitle("Pick an Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewIdea) {
                AddEditGiftIdeaView()
            }
            .sheet(item: $editingIdea) { idea in
                AddEditGiftIdeaView(giftIdea: idea)
            }
            .sheet(item: $selectedIdea) { idea in
                AddEditPurchaseView(eventPerson: eventPerson, prefill: idea)
            }
            .confirmationDialog(
                "Delete \"\(ideaToDelete?.name ?? "idea")\"?",
                isPresented: Binding(get: { ideaToDelete != nil }, set: { if !$0 { ideaToDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let idea = ideaToDelete { modelContext.delete(idea) }
                    ideaToDelete = nil
                }
                Button("Cancel", role: .cancel) { ideaToDelete = nil }
            }
        }
    }
}
