//
//  TrajectorySearchView.swift
//  TrajectorySearch
//
//  Root TabView — Search / Ideas / Chains / Claims
//

import ComposableArchitecture
import SwiftUI

struct TrajectorySearchView: View {
    @Bindable var store: StoreOf<TrajectorySearchFeature>

    var body: some View {
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { store.send(.selectTab($0)) }
        )) {
            SearchView(
                store: store.scope(state: \.search, action: \.search)
            )
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
            .tag(TrajectorySearchFeature.State.Tab.search)

            IdeasView(
                store: store.scope(state: \.ideas, action: \.ideas)
            )
            .tabItem {
                Label("Ideas", systemImage: "lightbulb")
            }
            .tag(TrajectorySearchFeature.State.Tab.ideas)

            ChainsView(
                store: store.scope(state: \.chains, action: \.chains)
            )
            .tabItem {
                Label("Chains", systemImage: "link")
            }
            .tag(TrajectorySearchFeature.State.Tab.chains)

            ClaimsView(
                store: store.scope(state: \.claims, action: \.claims)
            )
            .tabItem {
                Label("Claims", systemImage: "checkmark.shield")
            }
            .tag(TrajectorySearchFeature.State.Tab.claims)
        }
    }
}

#Preview {
    TrajectorySearchView(
        store: Store(initialState: TrajectorySearchFeature.State()) {
            TrajectorySearchFeature()
        }
    )
}
