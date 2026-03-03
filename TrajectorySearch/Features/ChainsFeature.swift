//
//  ChainsFeature.swift
//  TrajectorySearch
//
//  TCA reducer: Knowledge chain composition and node linking
//

import ComposableArchitecture
import Foundation

@Reducer
struct ChainsFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var chains: IdentifiedArrayOf<KnowledgeChain> = []
        var isLoading: Bool = false
        var errorMessage: String?
        var selectedChainID: UUID?
        var showingNewChain: Bool = false
        var showingAddNode: Bool = false
        var editingNode: KnowledgeNode?
        var filterStatus: ChainStatus?

        var selectedChain: KnowledgeChain? {
            guard let id = selectedChainID else { return nil }
            return chains[id: id]
        }

        var filteredChains: IdentifiedArrayOf<KnowledgeChain> {
            var filtered = chains.elements
            if let status = filterStatus {
                filtered = filtered.filter { $0.status == status }
            }
            filtered.sort { $0.updatedAt > $1.updatedAt }
            return IdentifiedArrayOf(uniqueElements: filtered)
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // Lifecycle
        case onAppear
        case loadChains
        case chainsLoaded([KnowledgeChain])
        case loadFailed(String)

        // Chain CRUD
        case createChain(String, String)
        case chainCreated(KnowledgeChain)
        case updateChainStatus(UUID, ChainStatus)
        case deleteChain(UUID)
        case selectChain(UUID?)
        case showNewChain
        case hideNewChain

        // Node management
        case addNode(UUID, KnowledgeNode)
        case updateNode(UUID, KnowledgeNode)
        case removeNode(UUID, UUID)
        case moveNode(UUID, from: Int, to: Int)
        case toggleNodeCompleted(UUID, UUID)
        case showAddNode
        case hideAddNode
        case editNode(KnowledgeNode?)

        // Node linking
        case linkNodes(UUID, UUID, UUID)
        case unlinkNodes(UUID, UUID, UUID)

        // Filtering
        case filterByStatus(ChainStatus?)
    }

    // MARK: - Dependencies

    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .onAppear:
                return .send(.loadChains)

            case .loadChains:
                state.isLoading = true
                // Using preview data for now; Supabase integration can be wired later
                return .run { send in
                    try await Task.sleep(nanoseconds: 300_000_000)
                    await send(.chainsLoaded(KnowledgeChain.previewList))
                }

            case .chainsLoaded(let chains):
                state.isLoading = false
                state.chains = IdentifiedArrayOf(uniqueElements: chains)
                return .none

            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            // MARK: Chain CRUD

            case .createChain(let title, let description):
                let chain = KnowledgeChain(
                    id: uuid(),
                    title: title,
                    description: description,
                    createdAt: date.now,
                    updatedAt: date.now
                )
                return .send(.chainCreated(chain))

            case .chainCreated(let chain):
                state.chains.insert(chain, at: 0)
                state.showingNewChain = false
                state.selectedChainID = chain.id
                return .none

            case .updateChainStatus(let chainID, let status):
                if var chain = state.chains[id: chainID] {
                    chain.status = status
                    chain.updatedAt = date.now
                    state.chains[id: chainID] = chain
                }
                return .none

            case .deleteChain(let id):
                state.chains.remove(id: id)
                if state.selectedChainID == id {
                    state.selectedChainID = nil
                }
                return .none

            case .selectChain(let id):
                state.selectedChainID = id
                return .none

            case .showNewChain:
                state.showingNewChain = true
                return .none

            case .hideNewChain:
                state.showingNewChain = false
                return .none

            // MARK: Node Management

            case .addNode(let chainID, let node):
                if var chain = state.chains[id: chainID] {
                    var newNode = node
                    newNode.sortOrder = chain.nodes.count
                    chain.nodes.append(newNode)
                    chain.updatedAt = date.now
                    state.chains[id: chainID] = chain
                    state.showingAddNode = false
                }
                return .none

            case .updateNode(let chainID, let node):
                if var chain = state.chains[id: chainID] {
                    if let idx = chain.nodes.firstIndex(where: { $0.id == node.id }) {
                        chain.nodes[idx] = node
                        chain.updatedAt = date.now
                        state.chains[id: chainID] = chain
                    }
                    state.editingNode = nil
                }
                return .none

            case .removeNode(let chainID, let nodeID):
                if var chain = state.chains[id: chainID] {
                    chain.nodes.removeAll { $0.id == nodeID }
                    // Re-index sort orders
                    for i in 0..<chain.nodes.count {
                        chain.nodes[i].sortOrder = i
                    }
                    chain.updatedAt = date.now
                    state.chains[id: chainID] = chain
                }
                return .none

            case .moveNode(let chainID, let from, let to):
                if var chain = state.chains[id: chainID] {
                    guard from >= 0, from < chain.nodes.count,
                          to >= 0, to < chain.nodes.count,
                          from != to else { return .none }
                    let node = chain.nodes.remove(at: from)
                    chain.nodes.insert(node, at: to)
                    for i in 0..<chain.nodes.count {
                        chain.nodes[i].sortOrder = i
                    }
                    chain.updatedAt = date.now
                    state.chains[id: chainID] = chain
                }
                return .none

            case .toggleNodeCompleted(let chainID, let nodeID):
                if var chain = state.chains[id: chainID] {
                    if let idx = chain.nodes.firstIndex(where: { $0.id == nodeID }) {
                        chain.nodes[idx].isCompleted.toggle()
                        chain.updatedAt = date.now
                        state.chains[id: chainID] = chain
                    }
                }
                return .none

            case .showAddNode:
                state.showingAddNode = true
                return .none

            case .hideAddNode:
                state.showingAddNode = false
                return .none

            case .editNode(let node):
                state.editingNode = node
                return .none

            // MARK: Node Linking

            case .linkNodes(let chainID, let sourceID, let targetID):
                if var chain = state.chains[id: chainID] {
                    if let idx = chain.nodes.firstIndex(where: { $0.id == sourceID }) {
                        if !chain.nodes[idx].linkedNodeIds.contains(targetID) {
                            chain.nodes[idx].linkedNodeIds.append(targetID)
                            chain.updatedAt = date.now
                            state.chains[id: chainID] = chain
                        }
                    }
                }
                return .none

            case .unlinkNodes(let chainID, let sourceID, let targetID):
                if var chain = state.chains[id: chainID] {
                    if let idx = chain.nodes.firstIndex(where: { $0.id == sourceID }) {
                        chain.nodes[idx].linkedNodeIds.removeAll { $0 == targetID }
                        chain.updatedAt = date.now
                        state.chains[id: chainID] = chain
                    }
                }
                return .none

            // MARK: Filtering

            case .filterByStatus(let status):
                state.filterStatus = status
                return .none
            }
        }
    }
}
