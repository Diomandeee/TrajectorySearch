//
//  Idea.swift
//  TrajectorySearch
//
//  Ideas vault model — captures, tags, and links creative insights
//

import Foundation

struct Idea: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var tags: [String]
    var category: IdeaCategory
    var status: IdeaStatus
    var priority: IdeaPriority
    var links: [IdeaLink]
    var source: String?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, tags, category, status, priority, links, source, notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        tags: [String] = [],
        category: IdeaCategory = .general,
        status: IdeaStatus = .captured,
        priority: IdeaPriority = .medium,
        links: [IdeaLink] = [],
        source: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tags = tags
        self.category = category
        self.status = status
        self.priority = priority
        self.links = links
        self.source = source
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum IdeaCategory: String, Codable, CaseIterable, Sendable {
    case general
    case research
    case product
    case architecture
    case creative
    case business
    case personal

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .general: return "lightbulb"
        case .research: return "magnifyingglass"
        case .product: return "shippingbox"
        case .architecture: return "building.2"
        case .creative: return "paintpalette"
        case .business: return "chart.line.uptrend.xyaxis"
        case .personal: return "person"
        }
    }
}

enum IdeaStatus: String, Codable, CaseIterable, Sendable {
    case captured
    case exploring
    case developing
    case validating
    case implemented
    case archived

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .captured: return "sparkles"
        case .exploring: return "binoculars"
        case .developing: return "hammer"
        case .validating: return "checkmark.shield"
        case .implemented: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }

    var isActive: Bool {
        switch self {
        case .implemented, .archived: return false
        default: return true
        }
    }
}

enum IdeaPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    case critical

    var displayName: String {
        rawValue.capitalized
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "blue"
        case .low: return "gray"
        }
    }
}

struct IdeaLink: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var targetId: UUID
    var linkType: LinkType
    var label: String?

    enum CodingKeys: String, CodingKey {
        case id
        case targetId = "target_id"
        case linkType = "link_type"
        case label
    }

    init(
        id: UUID = UUID(),
        targetId: UUID,
        linkType: LinkType = .related,
        label: String? = nil
    ) {
        self.id = id
        self.targetId = targetId
        self.linkType = linkType
        self.label = label
    }
}

enum LinkType: String, Codable, CaseIterable, Sendable {
    case related
    case dependsOn = "depends_on"
    case inspiredBy = "inspired_by"
    case contradicts
    case supports
    case extends

    var displayName: String {
        switch self {
        case .related: return "Related"
        case .dependsOn: return "Depends On"
        case .inspiredBy: return "Inspired By"
        case .contradicts: return "Contradicts"
        case .supports: return "Supports"
        case .extends: return "Extends"
        }
    }
}

// MARK: - Preview Data

extension Idea {
    static let preview = Idea(
        title: "Semantic Search for Knowledge Graphs",
        description: "Combine vector embeddings with graph traversal for deeper knowledge retrieval.",
        tags: ["search", "knowledge", "graphs"],
        category: .architecture,
        status: .exploring,
        priority: .high
    )

    static let previewList: [Idea] = [
        Idea(
            title: "Semantic Search for Knowledge Graphs",
            description: "Combine vector embeddings with graph traversal for deeper knowledge retrieval.",
            tags: ["search", "knowledge", "graphs"],
            category: .architecture,
            status: .exploring,
            priority: .high
        ),
        Idea(
            title: "Voice-Controlled Idea Capture",
            description: "Use Whisper transcription to capture ideas hands-free while walking or driving.",
            tags: ["voice", "capture", "mobile"],
            category: .product,
            status: .captured,
            priority: .medium
        ),
        Idea(
            title: "Dream Pattern Analysis",
            description: "Track recurring themes in dream journals using NLP clustering.",
            tags: ["dreams", "analysis", "nlp"],
            category: .research,
            status: .developing,
            priority: .low
        ),
        Idea(
            title: "Automated Evidence Linking",
            description: "Auto-link claims to supporting documents using similarity scores.",
            tags: ["claims", "automation", "evidence"],
            category: .architecture,
            status: .validating,
            priority: .critical
        ),
    ]
}
