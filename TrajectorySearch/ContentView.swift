//
//  ContentView.swift
//  TrajectorySearch
//
//  Retained for backwards compatibility; main entry is TrajectorySearchView.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Trajectory Search")
                    .font(.largeTitle.bold())

                Text("Semantic search, ideas, chains, claims")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Trajectory Search")
        }
    }
}

#Preview {
    ContentView()
}
