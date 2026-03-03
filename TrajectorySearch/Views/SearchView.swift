//
//  SearchView.swift
//  TrajectorySearch
//
//  Semantic search — search bar + results list with relevance scores
//

import ComposableArchitecture
import SwiftUI

struct SearchView: View {
    @Bindable var store: StoreOf<SearchFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                if store.showingFilters {
                    filtersSection
                }

                // Content
                if store.isSearching {
                    loadingView
                } else if let error = store.errorMessage {
                    errorView(error)
                } else if store.showEmptyState {
                    emptyStateView
                } else if store.hasResults {
                    resultsList
                } else if !store.query.isEmpty {
                    noResultsView
                }
            }
            .navigationTitle("Semantic Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.toggleFilters)
                    } label: {
                        Image(systemName: store.showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - Bindings

    private var queryBinding: Binding<String> {
        Binding(
            get: { store.query },
            set: { store.send(.queryChanged($0)) }
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search knowledge...", text: queryBinding)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit {
                        store.send(.search)
                    }

                if !store.query.isEmpty {
                    Button {
                        store.send(.clearResults)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }

    // MARK: - Filters

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Min Score")
                    .font(.caption.weight(.medium))
                Slider(
                    value: Binding(
                        get: { store.filter.minScore },
                        set: { store.send(.updateMinScore($0)) }
                    ),
                    in: 0...1,
                    step: 0.1
                )
                Text(String(format: "%.1f", store.filter.minScore))
                    .font(.caption.monospacedDigit())
                    .frame(width: 30)
            }

            HStack {
                Text("Max Results")
                    .font(.caption.weight(.medium))
                Picker("", selection: Binding(
                    get: { store.filter.maxResults },
                    set: { store.send(.updateMaxResults($0)) }
                )) {
                    ForEach([10, 20, 50, 100], id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !store.filter.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(store.filter.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button {
                                    store.send(.removeTagFilter(tag))
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Results

    private var resultsList: some View {
        List {
            ForEach(store.results) { result in
                Button {
                    store.send(.selectResult(result.id))
                } label: {
                    SearchResultRow(result: result)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .sheet(item: Binding(
            get: { store.selectedResult },
            set: { _ in store.send(.selectResult(nil)) }
        )) { result in
            SearchResultDetailSheet(result: result)
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Search Error")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                store.send(.search)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.blue.opacity(0.6))

            Text("Semantic Search")
                .font(.title2.weight(.semibold))

            Text("Search your knowledge base using natural language.\nPowered by RAG++.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Recent searches
            if !store.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Clear") {
                            store.send(.clearHistory)
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal)

                    ForEach(store.searchHistory.prefix(5), id: \.self) { query in
                        Button {
                            store.send(.selectHistoryItem(query))
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(query)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Results")
                .font(.headline)
            Text("Try different keywords or adjust filters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(String(format: "%.0f%%", result.score * 100))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(scoreColor(result.score).opacity(0.15), in: Capsule())
                    .foregroundStyle(scoreColor(result.score))
            }

            Text(result.snippet)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Label(result.source, systemImage: "doc")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(result.relevanceLabel)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...: return .green
        case 0.75..<0.9: return .blue
        case 0.5..<0.75: return .orange
        default: return .gray
        }
    }
}

// MARK: - Detail Sheet

struct SearchResultDetailSheet: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Score badge
                    HStack {
                        Label(result.relevanceLabel, systemImage: "chart.bar.fill")
                            .font(.subheadline.weight(.medium))

                        Spacer()

                        Text(String(format: "%.1f%% relevance", result.score * 100))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Content
                    Text(result.snippet)
                        .font(.body)

                    Divider()

                    // Source
                    Label(result.source, systemImage: "doc.text")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Metadata
                    if let meta = result.metadata {
                        VStack(alignment: .leading, spacing: 8) {
                            if let docType = meta.documentType {
                                Label(docType, systemImage: "doc.badge.gearshape")
                                    .font(.caption)
                            }
                            if let author = meta.author {
                                Label(author, systemImage: "person")
                                    .font(.caption)
                            }
                            if let tags = meta.tags, !tags.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(.blue.opacity(0.1), in: Capsule())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(result.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SearchView(
        store: Store(initialState: SearchFeature.State()) {
            SearchFeature()
        } withDependencies: {
            $0.ragClient = .previewValue
        }
    )
}
