//
//  GiftIdeaPickerSheet.swift
//  Event Budgeter
//
//  The single "add a gift" hub: a prominent New Gift button plus the
//  reusable gift ideas, prioritized for the selected person.
//

import SwiftUI
import SwiftData

struct GiftIdeaPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let eventPerson: EventPerson
    var onGiftSaved: (() -> Void)? = nil
    @Query(sort: \GiftIdea.name) private var allIdeas: [GiftIdea]

    @State private var searchText = ""
    @State private var showingNewIdea = false
    @State private var showingBlankGift = false
    @State private var selectedIdea: GiftIdea?
    @State private var editingIdea: GiftIdea?
    @State private var ideaToDelete: GiftIdea?
    @State private var convertedIdea: GiftIdea?

    private var personID: PersistentIdentifier? { eventPerson.person?.persistentModelID }
    private var personName: String { eventPerson.person?.name ?? "" }

    private var cashGiftIdea: GiftIdea? {
        allIdeas.first { $0.isCashGift }
    }

    private var regularIdeas: [GiftIdea] {
        let items = allIdeas.filter { !$0.isCashGift }
        if searchText.isEmpty { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var personIdeas: [GiftIdea] {
        guard let pid = personID else { return [] }
        return regularIdeas.filter { idea in idea.people.contains { $0.persistentModelID == pid } }
    }

    private var otherIdeas: [GiftIdea] {
        guard let pid = personID else { return regularIdeas }
        return regularIdeas.filter { idea in !idea.people.contains { $0.persistentModelID == pid } }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Button {
                    showingBlankGift = true
                } label: {
                    Label("New Gift", systemImage: "gift")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                List {
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

                    if regularIdeas.isEmpty {
                        ContentUnavailableView(
                            searchText.isEmpty ? "No Ideas Yet" : "No Results",
                            systemImage: "lightbulb",
                            description: Text(searchText.isEmpty
                                ? "Save ideas here to reuse them when buying gifts."
                                : "No ideas match \"\(searchText)\".")
                        )
                    } else {
                        if !personIdeas.isEmpty {
                            Section("For \(personName)") {
                                ForEach(personIdeas) { idea in ideaRow(idea) }
                            }
                        }
                        if !otherIdeas.isEmpty {
                            Section(personIdeas.isEmpty ? "Ideas" : "All Ideas") {
                                ForEach(otherIdeas) { idea in ideaRow(idea) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search ideas")
            }
            .navigationTitle("Add a Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingNewIdea) {
                AddEditGiftIdeaView()
            }
            .sheet(isPresented: $showingBlankGift) {
                AddEditPurchaseView(eventPerson: eventPerson,
                                    onSave: { onGiftSaved?(); dismiss() })
            }
            .sheet(item: $editingIdea) { idea in
                AddEditGiftIdeaView(giftIdea: idea)
            }
            .sheet(item: $selectedIdea) { idea in
                AddEditPurchaseView(eventPerson: eventPerson, prefill: idea, onSave: {
                    if idea.isCashGift {
                        onGiftSaved?()
                        dismiss()
                    } else {
                        convertedIdea = idea
                    }
                })
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
            .confirmationDialog(
                "Delete the idea \"\(convertedIdea?.name ?? "")\"?",
                isPresented: Binding(get: { convertedIdea != nil }, set: { if !$0 { convertedIdea = nil } }),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let idea = convertedIdea { modelContext.delete(idea) }
                    convertedIdea = nil
                    onGiftSaved?()
                    dismiss()
                }
                Button("Keep", role: .cancel) {
                    convertedIdea = nil
                    onGiftSaved?()
                    dismiss()
                }
            } message: {
                Text("The gift was added. You can remove the idea if you won't reuse it.")
            }
        }
    }

    @ViewBuilder
    private func ideaRow(_ idea: GiftIdea) -> some View {
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
