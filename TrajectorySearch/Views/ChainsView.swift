//
//  ChainsView.swift
//  TrajectorySearch
//
//  Knowledge chain builder — compose chains of linked nodes
//

import ComposableArchitecture
import SwiftUI

struct ChainsView: View {
    @Bindable var store: StoreOf<ChainsFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading chains...")
                } else if store.filteredChains.isEmpty {
                    emptyState
                } else {
                    chainsList
                }
            }
            .navigationTitle("Knowledge Chains")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.showNewChain)
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All") {
                            store.send(.filterByStatus(nil))
                        }
                        ForEach(ChainStatus.allCases, id: \.self) { status in
                            Button {
                                store.send(.filterByStatus(status))
                            } label: {
                                Label(status.displayName, systemImage: status.icon)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { store.showingNewChain },
                set: { newVal in if newVal { store.send(.showNewChain) } else { store.send(.hideNewChain) } }
            )) {
                NewChainSheet { title, description in
                    store.send(.createChain(title, description))
                } onCancel: {
                    store.send(.hideNewChain)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - Chains List

    private var chainsList: some View {
        List {
            ForEach(store.filteredChains) { chain in
                NavigationLink {
                    ChainDetailView(
                        chain: chain,
                        onAddNode: { node in
                            store.send(.addNode(chain.id, node))
                        },
                        onToggleNode: { nodeID in
                            store.send(.toggleNodeCompleted(chain.id, nodeID))
                        },
                        onRemoveNode: { nodeID in
                            store.send(.removeNode(chain.id, nodeID))
                        },
                        onUpdateStatus: { status in
                            store.send(.updateChainStatus(chain.id, status))
                        }
                    )
                } label: {
                    ChainRow(chain: chain)
                }
            }
            .onDelete { indexSet in
                let chains = store.filteredChains
                for index in indexSet {
                    store.send(.deleteChain(chains[index].id))
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "link")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.6))

            Text("No Chains Yet")
                .font(.title2.weight(.semibold))

            Text("Build knowledge chains by linking\nconcepts, facts, and insights.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                store.send(.showNewChain)
            } label: {
                Label("New Chain", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

// MARK: - Chain Row

struct ChainRow: View {
    let chain: KnowledgeChain

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(chain.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Label(chain.status.displayName, systemImage: chain.status.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.1), in: Capsule())
            }

            if !chain.description.isEmpty {
                Text(chain.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                // Node count
                Label("\(chain.nodeCount) nodes", systemImage: "circle.grid.3x3")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                // Progress
                if chain.nodeCount > 0 {
                    HStack(spacing: 4) {
                        ProgressView(value: chain.progress)
                            .frame(width: 60)
                        Text("\(chain.completedNodeCount)/\(chain.nodeCount)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Tags
            if !chain.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(chain.tags.prefix(4), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.purple.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chain Detail View

struct ChainDetailView: View {
    let chain: KnowledgeChain
    let onAddNode: (KnowledgeNode) -> Void
    let onToggleNode: (UUID) -> Void
    let onRemoveNode: (UUID) -> Void
    let onUpdateStatus: (ChainStatus) -> Void

    @State private var showingAddNode = false
    @State private var newNodeTitle = ""
    @State private var newNodeType: NodeType = .concept
    @State private var newNodeContent = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(chain.title)
                        .font(.title2.weight(.bold))

                    if !chain.description.isEmpty {
                        Text(chain.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label(chain.status.displayName, systemImage: chain.status.icon)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1), in: Capsule())

                        Spacer()

                        if chain.nodeCount > 0 {
                            Text(String(format: "%.0f%% complete", chain.progress * 100))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if chain.nodeCount > 0 {
                        ProgressView(value: chain.progress)
                            .tint(.blue)
                    }
                }

                Divider()

                // Status selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ChainStatus.allCases, id: \.self) { status in
                                Button {
                                    onUpdateStatus(status)
                                } label: {
                                    Label(status.displayName, systemImage: status.icon)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            chain.status == status
                                                ? Color.blue.opacity(0.2)
                                                : Color.gray.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(chain.status == status ? .blue : .secondary)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Nodes
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Nodes")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingAddNode = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }

                    if chain.nodes.isEmpty {
                        Text("No nodes yet. Add your first knowledge node.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(chain.nodes.sorted(by: { $0.sortOrder < $1.sortOrder })) { node in
                            NodeCard(
                                node: node,
                                onToggle: { onToggleNode(node.id) },
                                onRemove: { onRemoveNode(node.id) }
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddNode) {
            NavigationStack {
                Form {
                    Section("Node") {
                        TextField("Title", text: $newNodeTitle)

                        Picker("Type", selection: $newNodeType) {
                            ForEach(NodeType.allCases, id: \.self) { type in
                                Label(type.displayName, systemImage: type.icon).tag(type)
                            }
                        }

                        TextField("Content", text: $newNodeContent, axis: .vertical)
                            .lineLimit(3...8)
                    }
                }
                .navigationTitle("Add Node")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddNode = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let node = KnowledgeNode(
                                title: newNodeTitle,
                                content: newNodeContent,
                                nodeType: newNodeType
                            )
                            onAddNode(node)
                            newNodeTitle = ""
                            newNodeContent = ""
                            newNodeType = .concept
                            showingAddNode = false
                        }
                        .disabled(newNodeTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }
}

// MARK: - Node Card

struct NodeCard: View {
    let node: KnowledgeNode
    let onToggle: () -> Void
    let onRemove: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Chain connector
            VStack(spacing: 0) {
                Circle()
                    .fill(node.isCompleted ? Color.green : nodeColor)
                    .frame(width: 12, height: 12)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: node.nodeType.icon)
                        .font(.caption)
                        .foregroundStyle(nodeColor)

                    Text(node.title)
                        .font(.subheadline.weight(.medium))
                        .strikethrough(node.isCompleted)

                    Spacer()

                    Button {
                        onToggle()
                    } label: {
                        Image(systemName: node.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(node.isCompleted ? .green : .secondary)
                    }
                }

                if !node.content.isEmpty {
                    Text(node.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                HStack {
                    Text(node.nodeType.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(nodeColor.opacity(0.1), in: Capsule())

                    if let source = node.source {
                        Text(source)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption2)
                    }
                }
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .confirmationDialog("Remove Node?", isPresented: $showDeleteConfirmation) {
            Button("Remove", role: .destructive) { onRemove() }
        }
    }

    private var nodeColor: Color {
        switch node.nodeType {
        case .concept: return .purple
        case .fact: return .green
        case .question: return .orange
        case .reference: return .blue
        case .insight: return .pink
        case .example: return .teal
        }
    }
}

// MARK: - New Chain Sheet

struct NewChainSheet: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Chain") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New Chain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
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
    ChainsView(
        store: Store(initialState: ChainsFeature.State()) {
            ChainsFeature()
        }
    )
}
