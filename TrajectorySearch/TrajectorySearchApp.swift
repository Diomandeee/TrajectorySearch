//
//  TrajectorySearchApp.swift
//  TrajectorySearch
//
//  Semantic search, ideas vault, knowledge chains, claims verification
//

import ComposableArchitecture
import OpenClawCore
import SwiftUI

@main
struct TrajectorySearchApp: App {
    init() {
        KeychainHelper.service = "com.openclaw.trajectorysearch"
    }

    var body: some Scene {
        WindowGroup {
            TrajectorySearchView(
                store: Store(initialState: TrajectorySearchFeature.State()) {
                    TrajectorySearchFeature()
                }
            )
        }
    }
}
