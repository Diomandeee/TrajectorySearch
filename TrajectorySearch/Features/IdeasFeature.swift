//
//  IdeasFeature.swift
//  TrajectorySearch
//
//  TCA reducer: Ideas vault CRUD, tagging, and search
//

import ComposableArchitecture
import Foundation

@Reducer
struct IdeasFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var ideas: IdentifiedArrayOf<Idea> = []
        var isLoading: Bool = false
        var errorMessage: String?
        var searchQuery: String = ""
        var selectedIdeaID: UUID?
        var editingIdea: Idea?
        var showingNewIdea: Bool = false
        var filterCategory: IdeaCategory?
        var filterStatus: IdeaStatus?
        var sortBy: SortOption = .updatedAt

        var filteredIdeas: IdentifiedArrayOf<Idea> {
            var filtered = ideas.elements

            // Text search
            if !searchQuery.isEmpty {
                filtered = filtered.filter {
                    $0.title.localizedCaseInsensitiveContains(searchQuery)
                    || $0.description.localizedCaseInsensitiveContains(searchQuery)
                    || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
                }
            }

            // Category filter
            if let cat = filterCategory {
                filtered = filtered.filter { $0.category == cat }
            }

            // Status filter
            if let status = filterStatus {
                filtered = filtered.filter { $0.status == status }
            }

            // Sort
            switch sortBy {
            case .updatedAt:
                filtered.sort { $0.updatedAt > $1.updatedAt }
            case .createdAt:
                filtered.sort { $0.createdAt > $1.createdAt }
            case .priority:
                filtered.sort { $0.priority.sortOrder < $1.priority.sortOrder }
            case .title:
                filtered.sort { $0.title < $1.title }
            }

            return IdentifiedArrayOf(uniqueElements: filtered)
        }

        var selectedIdea: Idea? {
            guard let id = selectedIdeaID else { return nil }
            return ideas[id: id]
        }

        enum SortOption: String, CaseIterable, Sendable {
            case updatedAt = "Recent"
            case createdAt = "Created"
            case priority = "Priority"
            case title = "Title"
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // Lifecycle
        case onAppear
        case loadIdeas
        case ideasLoaded([Idea])
        case loadFailed(String)

        // CRUD
        case createIdea(String, String)
        case ideaCreated(Idea)
        case updateIdea(Idea)
        case ideaUpdated(Idea)
        case deleteIdea(UUID)
        case ideaDeleted(UUID)

        // Selection & editing
        case selectIdea(UUID?)
        case editIdea(Idea)
        case cancelEdit
        case saveEdit
        case showNewIdea
        case hideNewIdea

        // Editing fields
        case updateEditTitle(String)
        case updateEditDescription(String)
        case updateEditCategory(IdeaCategory)
        case updateEditStatus(IdeaStatus)
        case updateEditPriority(IdeaPriority)
        case addEditTag(String)
        case removeEditTag(String)
        case updateEditNotes(String)

        // Filters & search
        case searchChanged(String)
        case filterByCategory(IdeaCategory?)
        case filterByStatus(IdeaStatus?)
        case setSortBy(State.SortOption)

        // Error handling
        case operationFailed(String)
    }

    // MARK: - Dependencies

    @Dependency(\.ideasClient) var ideasClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .onAppear:
                return .send(.loadIdeas)

            case .loadIdeas:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    let ideas = try await ideasClient.fetchAll()
                    await send(.ideasLoaded(ideas))
                } catch: { error, send in
                    await send(.loadFailed(error.localizedDescription))
                }

            case .ideasLoaded(let ideas):
                state.isLoading = false
                state.ideas = IdentifiedArrayOf(uniqueElements: ideas)
                return .none

            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            // MARK: CRUD

            case .createIdea(let title, let description):
                let idea = Idea(
                    id: uuid(),
                    title: title,
                    description: description,
                    createdAt: date.now,
                    updatedAt: date.now
                )
                return .run { send in
                    let created = try await ideasClient.create(idea)
                    await send(.ideaCreated(created))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .ideaCreated(let idea):
                state.ideas.insert(idea, at: 0)
                state.showingNewIdea = false
                return .none

            case .updateIdea(let idea):
                return .run { send in
                    let updated = try await ideasClient.update(idea)
                    await send(.ideaUpdated(updated))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .ideaUpdated(let idea):
                state.ideas[id: idea.id] = idea
                state.editingIdea = nil
                return .none

            case .deleteIdea(let id):
                return .run { send in
                    try await ideasClient.delete(id)
                    await send(.ideaDeleted(id))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .ideaDeleted(let id):
                state.ideas.remove(id: id)
                if state.selectedIdeaID == id {
                    state.selectedIdeaID = nil
                }
                return .none

            // MARK: Selection & Editing

            case .selectIdea(let id):
                state.selectedIdeaID = id
                return .none

            case .editIdea(let idea):
                state.editingIdea = idea
                return .none

            case .cancelEdit:
                state.editingIdea = nil
                return .none

            case .saveEdit:
                guard var idea = state.editingIdea else { return .none }
                idea.updatedAt = date.now
                return .send(.updateIdea(idea))

            case .showNewIdea:
                state.showingNewIdea = true
                state.editingIdea = Idea(
                    id: uuid(),
                    title: "",
                    createdAt: date.now,
                    updatedAt: date.now
                )
                return .none

            case .hideNewIdea:
                state.showingNewIdea = false
                state.editingIdea = nil
                return .none

            // MARK: Editing Fields

            case .updateEditTitle(let title):
                state.editingIdea?.title = title
                return .none

            case .updateEditDescription(let description):
                state.editingIdea?.description = description
                return .none

            case .updateEditCategory(let category):
                state.editingIdea?.category = category
                return .none

            case .updateEditStatus(let status):
                state.editingIdea?.status = status
                return .none

            case .updateEditPriority(let priority):
                state.editingIdea?.priority = priority
                return .none

            case .addEditTag(let tag):
                let trimmed = tag.trimmingCharacters(in: .whitespaces).lowercased()
                if !trimmed.isEmpty, !(state.editingIdea?.tags.contains(trimmed) ?? false) {
                    state.editingIdea?.tags.append(trimmed)
                }
                return .none

            case .removeEditTag(let tag):
                state.editingIdea?.tags.removeAll { $0 == tag }
                return .none

            case .updateEditNotes(let notes):
                state.editingIdea?.notes = notes
                return .none

            // MARK: Filters & Search

            case .searchChanged(let query):
                state.searchQuery = query
                return .none

            case .filterByCategory(let category):
                state.filterCategory = category
                return .none

            case .filterByStatus(let status):
                state.filterStatus = status
                return .none

            case .setSortBy(let option):
                state.sortBy = option
                return .none

            // MARK: Error

            case .operationFailed(let message):
                state.errorMessage = message
                return .none
            }
        }
    }
}
