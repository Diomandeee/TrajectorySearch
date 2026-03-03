//
//  SearchFeature.swift
//  TrajectorySearch
//
//  TCA reducer: semantic search with RAG++ service
//

import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var query: String = ""
        var results: IdentifiedArrayOf<SearchResult> = []
        var isSearching: Bool = false
        var errorMessage: String?
        var searchHistory: [String] = []
        var filter: SearchFilter = SearchFilter()
        var selectedResultID: UUID?
        var showingFilters: Bool = false

        var hasResults: Bool { !results.isEmpty }
        var showEmptyState: Bool { !isSearching && query.isEmpty && results.isEmpty }

        var selectedResult: SearchResult? {
            guard let id = selectedResultID else { return nil }
            return results[id: id]
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // Lifecycle
        case onAppear
        case loadHistory

        // Search
        case queryChanged(String)
        case search
        case searchCompleted([SearchResult])
        case searchFailed(String)
        case clearResults

        // History
        case historyLoaded([String])
        case selectHistoryItem(String)
        case clearHistory

        // Filters
        case toggleFilters
        case updateMinScore(Double)
        case updateMaxResults(Int)
        case updateSourceFilter(String)
        case addTagFilter(String)
        case removeTagFilter(String)

        // Selection
        case selectResult(UUID?)
    }

    // MARK: - Dependencies

    @Dependency(\.ragClient) var ragClient
    @Dependency(\.continuousClock) var clock

    // MARK: - Debounce ID

    private enum CancelID: Hashable {
        case searchDebounce
    }

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .onAppear:
                return .send(.loadHistory)

            case .loadHistory:
                return .run { send in
                    let history = await ragClient.searchHistory()
                    await send(.historyLoaded(history))
                }

            // MARK: Search

            case .queryChanged(let query):
                state.query = query
                state.errorMessage = nil

                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.results = []
                    return .cancel(id: CancelID.searchDebounce)
                }

                // Debounce search by 400ms
                return .run { send in
                    try await clock.sleep(for: .milliseconds(400))
                    await send(.search)
                }
                .cancellable(id: CancelID.searchDebounce, cancelInFlight: true)

            case .search:
                let query = state.query.trimmingCharacters(in: .whitespaces)
                guard !query.isEmpty else { return .none }

                state.isSearching = true
                state.errorMessage = nil
                let filter = state.filter

                return .run { send in
                    SearchHistoryManager.addQuery(query)
                    let results = try await ragClient.search(query, filter)
                    await send(.searchCompleted(results))
                } catch: { error, send in
                    await send(.searchFailed(error.localizedDescription))
                }

            case .searchCompleted(let results):
                state.isSearching = false
                state.results = IdentifiedArrayOf(uniqueElements: results)
                return .none

            case .searchFailed(let message):
                state.isSearching = false
                state.errorMessage = message
                return .none

            case .clearResults:
                state.query = ""
                state.results = []
                state.errorMessage = nil
                state.selectedResultID = nil
                return .cancel(id: CancelID.searchDebounce)

            // MARK: History

            case .historyLoaded(let history):
                state.searchHistory = history
                return .none

            case .selectHistoryItem(let query):
                state.query = query
                return .send(.search)

            case .clearHistory:
                state.searchHistory = []
                return .run { _ in
                    await ragClient.clearHistory()
                }

            // MARK: Filters

            case .toggleFilters:
                state.showingFilters.toggle()
                return .none

            case .updateMinScore(let score):
                state.filter.minScore = score
                return .none

            case .updateMaxResults(let max):
                state.filter.maxResults = max
                return .none

            case .updateSourceFilter(let source):
                state.filter.sourceFilter = source.isEmpty ? nil : source
                return .none

            case .addTagFilter(let tag):
                if !state.filter.tags.contains(tag) {
                    state.filter.tags.append(tag)
                }
                return .none

            case .removeTagFilter(let tag):
                state.filter.tags.removeAll { $0 == tag }
                return .none

            // MARK: Selection

            case .selectResult(let id):
                state.selectedResultID = id
                return .none
            }
        }
    }
}
