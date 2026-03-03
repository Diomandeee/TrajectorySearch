//
//  KnowledgeChain.swift
//  TrajectorySearch
//
//  Knowledge chains — linked sequences of knowledge nodes
//

import Foundation

struct KnowledgeChain: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var nodes: [KnowledgeNode]
    var status: ChainStatus
    var tags: [String]
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, nodes, status, tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        nodes: [KnowledgeNode] = [],
        status: ChainStatus = .draft,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.nodes = nodes
        self.status = status
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var nodeCount: Int { nodes.count }

    var completedNodeCount: Int {
        nodes.filter { $0.isCompleted }.count
    }

    var progress: Double {
        guard !nodes.isEmpty else { return 0 }
        return Double(completedNodeCount) / Double(nodeCount)
    }
}

struct KnowledgeNode: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var nodeType: NodeType
    var source: String?
    var sourceUrl: String?
    var sortOrder: Int
    var isCompleted: Bool
    var linkedNodeIds: [UUID]
    var metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id, title, content, source, metadata
        case nodeType = "node_type"
        case sourceUrl = "source_url"
        case sortOrder = "sort_order"
        case isCompleted = "is_completed"
        case linkedNodeIds = "linked_node_ids"
    }

    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        nodeType: NodeType = .concept,
        source: String? = nil,
        sourceUrl: String? = nil,
        sortOrder: Int = 0,
        isCompleted: Bool = false,
        linkedNodeIds: [UUID] = [],
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.nodeType = nodeType
        self.source = source
        self.sourceUrl = sourceUrl
        self.sortOrder = sortOrder
        self.isCompleted = isCompleted
        self.linkedNodeIds = linkedNodeIds
        self.metadata = metadata
    }
}

enum NodeType: String, Codable, CaseIterable, Sendable {
    case concept
    case fact
    case question
    case reference
    case insight
    case example

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .concept: return "lightbulb"
        case .fact: return "checkmark.seal"
        case .question: return "questionmark.circle"
        case .reference: return "book"
        case .insight: return "brain.head.profile"
        case .example: return "doc.text"
        }
    }

    var color: String {
        switch self {
        case .concept: return "purple"
        case .fact: return "green"
        case .question: return "orange"
        case .reference: return "blue"
        case .insight: return "pink"
        case .example: return "teal"
        }
    }
}

enum ChainStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case inProgress = "in_progress"
    case review
    case complete
    case archived

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .inProgress: return "In Progress"
        case .review: return "Review"
        case .complete: return "Complete"
        case .archived: return "Archived"
        }
    }

    var icon: String {
        switch self {
        case .draft: return "doc"
        case .inProgress: return "arrow.right.circle"
        case .review: return "eye"
        case .complete: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }
}

// MARK: - Preview Data

extension KnowledgeChain {
    static let preview = KnowledgeChain(
        title: "RAG Pipeline Architecture",
        description: "Understanding the retrieval-augmented generation pipeline from embedding to response.",
        nodes: KnowledgeNode.previewList,
        status: .inProgress,
        tags: ["rag", "architecture", "ml"]
    )

    static let previewList: [KnowledgeChain] = [
        KnowledgeChain(
            title: "RAG Pipeline Architecture",
            description: "Understanding the retrieval-augmented generation pipeline.",
            nodes: KnowledgeNode.previewList,
            status: .inProgress,
            tags: ["rag", "architecture", "ml"]
        ),
        KnowledgeChain(
            title: "Distributed Systems Fundamentals",
            description: "Core concepts of distributed computing and consensus.",
            nodes: [
                KnowledgeNode(title: "CAP Theorem", nodeType: .concept, sortOrder: 0, isCompleted: true),
                KnowledgeNode(title: "Consensus Protocols", nodeType: .concept, sortOrder: 1),
            ],
            status: .draft,
            tags: ["distributed", "systems"]
        ),
        KnowledgeChain(
            title: "Swift Concurrency Model",
            description: "Actors, async/await, and structured concurrency in Swift.",
            nodes: [
                KnowledgeNode(title: "async/await", nodeType: .concept, sortOrder: 0, isCompleted: true),
                KnowledgeNode(title: "Actors", nodeType: .concept, sortOrder: 1, isCompleted: true),
                KnowledgeNode(title: "Task Groups", nodeType: .concept, sortOrder: 2),
            ],
            status: .review,
            tags: ["swift", "concurrency"]
        ),
    ]
}

extension KnowledgeNode {
    static let previewList: [KnowledgeNode] = [
        KnowledgeNode(
            title: "Document Embedding",
            content: "Convert documents into vector representations using transformer models.",
            nodeType: .concept,
            source: "rag-overview.md",
            sortOrder: 0,
            isCompleted: true
        ),
        KnowledgeNode(
            title: "Vector Store Indexing",
            content: "Store embeddings in a vector database for efficient similarity search.",
            nodeType: .fact,
            source: "vector-stores.md",
            sortOrder: 1,
            isCompleted: true
        ),
        KnowledgeNode(
            title: "Query Embedding & Retrieval",
            content: "Transform user queries into embeddings and retrieve top-k similar documents.",
            nodeType: .concept,
            sortOrder: 2
        ),
        KnowledgeNode(
            title: "Re-ranking Strategy",
            content: "What re-ranking approach maximizes relevance without excessive latency?",
            nodeType: .question,
            sortOrder: 3
        ),
    ]
}
