//
//  TrajectorySearchFeature.swift
//  TrajectorySearch
//
//  Root TCA reducer — TabView state composing child features
//

import ComposableArchitecture
import Foundation

@Reducer
struct TrajectorySearchFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .search
        var search = SearchFeature.State()
        var ideas = IdeasFeature.State()
        var chains = ChainsFeature.State()
        var claims = ClaimsFeature.State()

        enum Tab: String, CaseIterable, Identifiable, Sendable {
            case search = "Search"
            case ideas = "Ideas"
            case chains = "Chains"
            case claims = "Claims"

            var id: String { rawValue }

            var icon: String {
                switch self {
                case .search: return "magnifyingglass"
                case .ideas: return "lightbulb"
                case .chains: return "link"
                case .claims: return "checkmark.shield"
                }
            }
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        case selectTab(State.Tab)
        case search(SearchFeature.Action)
        case ideas(IdeasFeature.Action)
        case chains(ChainsFeature.Action)
        case claims(ClaimsFeature.Action)
    }

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Scope(state: \.search, action: \.search) {
            SearchFeature()
        }
        Scope(state: \.ideas, action: \.ideas) {
            IdeasFeature()
        }
        Scope(state: \.chains, action: \.chains) {
            ChainsFeature()
        }
        Scope(state: \.claims, action: \.claims) {
            ClaimsFeature()
        }
        Reduce { state, action in
            switch action {
            case .selectTab(let tab):
                state.selectedTab = tab
                return .none

            case .search, .ideas, .chains, .claims:
                return .none
            }
        }
    }
}
