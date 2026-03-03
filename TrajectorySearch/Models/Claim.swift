//
//  Claim.swift
//  TrajectorySearch
//
//  Claims verification — track claims with evidence and verdicts
//

import Foundation

struct Claim: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var statement: String
    var description: String
    var verdict: ClaimVerdict
    var confidence: Double
    var evidence: [Evidence]
    var source: String?
    var category: ClaimCategory
    var tags: [String]
    var reviewedAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, statement, description, verdict, confidence, evidence, source, category, tags
        case reviewedAt = "reviewed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        statement: String,
        description: String = "",
        verdict: ClaimVerdict = .unverified,
        confidence: Double = 0.0,
        evidence: [Evidence] = [],
        source: String? = nil,
        category: ClaimCategory = .general,
        tags: [String] = [],
        reviewedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.statement = statement
        self.description = description
        self.verdict = verdict
        self.confidence = confidence
        self.evidence = evidence
        self.source = source
        self.category = category
        self.tags = tags
        self.reviewedAt = reviewedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var confidenceLabel: String {
        switch confidence {
        case 0.9...: return "Very High"
        case 0.7..<0.9: return "High"
        case 0.5..<0.7: return "Moderate"
        case 0.3..<0.5: return "Low"
        default: return "Very Low"
        }
    }

    var supportingCount: Int {
        evidence.filter { $0.stance == .supporting }.count
    }

    var contradictingCount: Int {
        evidence.filter { $0.stance == .contradicting }.count
    }
}

enum ClaimVerdict: String, Codable, CaseIterable, Sendable {
    case verified
    case falsified
    case partial
    case disputed
    case unverified

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .falsified: return "xmark.seal.fill"
        case .partial: return "checkmark.circle"
        case .disputed: return "exclamationmark.triangle.fill"
        case .unverified: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .verified: return "green"
        case .falsified: return "red"
        case .partial: return "orange"
        case .disputed: return "yellow"
        case .unverified: return "gray"
        }
    }
}

enum ClaimCategory: String, Codable, CaseIterable, Sendable {
    case general
    case technical
    case scientific
    case historical
    case business
    case personal

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .general: return "doc.text"
        case .technical: return "wrench.and.screwdriver"
        case .scientific: return "flask"
        case .historical: return "clock.arrow.circlepath"
        case .business: return "briefcase"
        case .personal: return "person"
        }
    }
}

struct Evidence: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var source: String
    var sourceUrl: String?
    var stance: EvidenceStance
    var strength: Double
    var addedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, source, stance, strength
        case sourceUrl = "source_url"
        case addedAt = "added_at"
    }

    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        source: String,
        sourceUrl: String? = nil,
        stance: EvidenceStance = .supporting,
        strength: Double = 0.5,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.source = source
        self.sourceUrl = sourceUrl
        self.stance = stance
        self.strength = strength
        self.addedAt = addedAt
    }
}

enum EvidenceStance: String, Codable, CaseIterable, Sendable {
    case supporting
    case contradicting
    case neutral

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .supporting: return "hand.thumbsup"
        case .contradicting: return "hand.thumbsdown"
        case .neutral: return "minus.circle"
        }
    }

    var color: String {
        switch self {
        case .supporting: return "green"
        case .contradicting: return "red"
        case .neutral: return "gray"
        }
    }
}

// MARK: - Preview Data

extension Claim {
    static let preview = Claim(
        statement: "Vector databases outperform traditional SQL for similarity search at scale",
        description: "Comparing vector database performance against PostgreSQL with pgvector for 1M+ document collections.",
        verdict: .verified,
        confidence: 0.88,
        evidence: Evidence.previewList,
        category: .technical,
        tags: ["databases", "vectors", "performance"]
    )

    static let previewList: [Claim] = [
        Claim(
            statement: "Vector databases outperform SQL for similarity search at scale",
            description: "Performance comparison at 1M+ documents.",
            verdict: .verified,
            confidence: 0.88,
            evidence: [Evidence.previewList[0]],
            category: .technical,
            tags: ["databases", "vectors"]
        ),
        Claim(
            statement: "LLM hallucination rates decrease linearly with RAG context size",
            description: "Testing whether more context always reduces hallucination.",
            verdict: .partial,
            confidence: 0.62,
            evidence: [],
            category: .scientific,
            tags: ["llm", "rag", "hallucination"]
        ),
        Claim(
            statement: "GraphQL reduces mobile data transfer by 40% vs REST",
            description: "Measuring bandwidth savings across typical mobile API patterns.",
            verdict: .disputed,
            confidence: 0.45,
            evidence: [],
            category: .technical,
            tags: ["graphql", "rest", "mobile"]
        ),
        Claim(
            statement: "Spaced repetition improves long-term knowledge retention by 200%",
            description: "Meta-analysis of spaced repetition studies.",
            verdict: .unverified,
            confidence: 0.0,
            category: .scientific,
            tags: ["learning", "memory"]
        ),
    ]
}

extension Evidence {
    static let previewList: [Evidence] = [
        Evidence(
            title: "Pinecone Benchmark Report",
            content: "At 1M vectors, Pinecone queries averaged 12ms vs 340ms for pgvector.",
            source: "pinecone-benchmarks.pdf",
            stance: .supporting,
            strength: 0.9
        ),
        Evidence(
            title: "pgvector 0.6.0 Improvements",
            content: "pgvector 0.6.0 introduced HNSW indexing, reducing query times to ~50ms at 1M vectors.",
            source: "pgvector-changelog.md",
            stance: .contradicting,
            strength: 0.6
        ),
        Evidence(
            title: "Weaviate vs PostgreSQL Analysis",
            content: "Weaviate showed 5x throughput advantage for concurrent similarity queries.",
            source: "db-comparison-2024.pdf",
            stance: .supporting,
            strength: 0.75
        ),
    ]
}
