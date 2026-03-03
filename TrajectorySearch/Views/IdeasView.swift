//
//  IdeasView.swift
//  TrajectorySearch
//
//  Ideas list with filters, categories, and search
//

import ComposableArchitecture
import SwiftUI

struct IdeasView: View {
    @Bindable var store: StoreOf<IdeasFeature>

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Ideas Vault")
                .searchable(
                    text: searchQueryBinding,
                    prompt: "Search ideas..."
                )
                .toolbar {
                    addButton
                    filterMenu
                }
                .sheet(isPresented: showingNewIdeaBinding) {
                    newIdeaSheet
                }
                .onAppear {
                    store.send(.onAppear)
                }
        }
    }

    // MARK: - Body Sub-Views

    @ViewBuilder
    private var contentView: some View {
        if store.isLoading {
            ProgressView("Loading ideas...")
        } else if store.filteredIdeas.isEmpty {
            emptyState
        } else {
            ideasList
        }
    }

    private var searchQueryBinding: Binding<String> {
        Binding(
            get: { store.searchQuery },
            set: { store.send(.searchChanged($0)) }
        )
    }

    private var showingNewIdeaBinding: Binding<Bool> {
        Binding(
            get: { store.showingNewIdea },
            set: { newVal in
                if newVal { store.send(.showNewIdea) } else { store.send(.hideNewIdea) }
            }
        )
    }

    // MARK: - Toolbar

    private var addButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.showNewIdea)
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private var filterMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                sortSection
                categorySection
                statusSection
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
    }

    @ViewBuilder
    private var sortSection: some View {
        Section("Sort By") {
            ForEach(IdeasFeature.State.SortOption.allCases, id: \.self) { option in
                Button {
                    store.send(.setSortBy(option))
                } label: {
                    if store.sortBy == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var categorySection: some View {
        Section("Category") {
            Button("All Categories") {
                store.send(.filterByCategory(nil))
            }
            ForEach(IdeaCategory.allCases, id: \.self) { cat in
                Button {
                    store.send(.filterByCategory(cat))
                } label: {
                    Label(cat.displayName, systemImage: cat.icon)
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        Section("Status") {
            Button("All Statuses") {
                store.send(.filterByStatus(nil))
            }
            ForEach(IdeaStatus.allCases, id: \.self) { status in
                Button {
                    store.send(.filterByStatus(status))
                } label: {
                    Label(status.displayName, systemImage: status.icon)
                }
            }
        }
    }

    // MARK: - New Idea Sheet

    @ViewBuilder
    private var newIdeaSheet: some View {
        if let idea = store.editingIdea {
            IdeaEditorSheet(
                idea: idea,
                isNew: true,
                onSave: { title, description in
                    store.send(.createIdea(title, description))
                },
                onCancel: {
                    store.send(.hideNewIdea)
                }
            )
        }
    }

    // MARK: - Ideas List

    private var ideasList: some View {
        List {
            activeFiltersSection

            ForEach(store.filteredIdeas) { idea in
                NavigationLink {
                    IdeaDetailView(
                        idea: idea,
                        onEdit: { store.send(.editIdea(idea)) },
                        onDelete: { store.send(.deleteIdea(idea.id)) },
                        onStatusChange: { status in
                            var updated = idea
                            updated.status = status
                            updated.updatedAt = Date()
                            store.send(.updateIdea(updated))
                        }
                    )
                } label: {
                    IdeaRow(idea: idea)
                }
            }
            .onDelete { indexSet in
                let ideas = store.filteredIdeas
                for index in indexSet {
                    store.send(.deleteIdea(ideas[index].id))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private var activeFiltersSection: some View {
        if store.filterCategory != nil || store.filterStatus != nil {
            Section {
                HStack {
                    if let cat = store.filterCategory {
                        Label(cat.displayName, systemImage: cat.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1), in: Capsule())
                    }
                    if let status = store.filterStatus {
                        Label(status.displayName, systemImage: status.icon)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.1), in: Capsule())
                    }
                    Spacer()
                    Button("Clear") {
                        store.send(.filterByCategory(nil))
                        store.send(.filterByStatus(nil))
                    }
                    .font(.caption)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lightbulb")
                .font(.system(size: 64))
                .foregroundStyle(.yellow.opacity(0.6))

            Text("No Ideas Yet")
                .font(.title2.weight(.semibold))

            Text("Capture your first idea.\nTag it, categorize it, and let it grow.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                store.send(.showNewIdea)
            } label: {
                Label("New Idea", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

// MARK: - Idea Row

struct IdeaRow: View {
    let idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: idea.category.icon)
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text(idea.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                priorityBadge
            }

            if !idea.description.isEmpty {
                Text(idea.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Label(idea.status.displayName, systemImage: idea.status.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                tagsRow
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var tagsRow: some View {
        if !idea.tags.isEmpty {
            HStack(spacing: 4) {
                ForEach(idea.tags.prefix(3), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1), in: Capsule())
                }
                if idea.tags.count > 3 {
                    Text("+\(idea.tags.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var priorityBadge: some View {
        Text(idea.priority.displayName)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.15), in: Capsule())
            .foregroundStyle(priorityColor)
    }

    private var priorityColor: Color {
        switch idea.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

// MARK: - New Idea Sheet

struct IdeaEditorSheet: View {
    let idea: Idea
    let isNew: Bool
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var title: String
    @State private var description: String

    @Environment(\.dismiss) private var dismiss

    init(idea: Idea, isNew: Bool, onSave: @escaping (String, String) -> Void, onCancel: @escaping () -> Void) {
        self.idea = idea
        self.isNew = isNew
        self.onSave = onSave
        self.onCancel = onCancel
        _title = State(initialValue: idea.title)
        _description = State(initialValue: idea.description)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle(isNew ? "New Idea" : "Edit Idea")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, description)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    IdeasView(
        store: Store(initialState: IdeasFeature.State()) {
            IdeasFeature()
        } withDependencies: {
            $0.ideasClient = .previewValue
        }
    )
}
