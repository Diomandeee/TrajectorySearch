//
//  SearchResult.swift
//  TrajectorySearch
//
//  Semantic search result from RAG++ service
//

import Foundation

struct SearchResult: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let score: Double
    let snippet: String
    let source: String
    let title: String
    var metadata: SearchMetadata?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, score, snippet, source, title, metadata
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        score: Double,
        snippet: String,
        source: String,
        title: String,
        metadata: SearchMetadata? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.score = score
        self.snippet = snippet
        self.source = source
        self.title = title
        self.metadata = metadata
        self.createdAt = createdAt
    }

    var relevanceLabel: String {
        switch score {
        case 0.9...: return "Exact"
        case 0.75..<0.9: return "High"
        case 0.5..<0.75: return "Medium"
        default: return "Low"
        }
    }

    var relevanceColor: String {
        switch score {
        case 0.9...: return "green"
        case 0.75..<0.9: return "blue"
        case 0.5..<0.75: return "orange"
        default: return "gray"
        }
    }
}

struct SearchMetadata: Codable, Equatable, Sendable {
    var documentType: String?
    var author: String?
    var tags: [String]?
    var chunkIndex: Int?
    var totalChunks: Int?
    var lastModified: Date?

    enum CodingKeys: String, CodingKey {
        case documentType = "document_type"
        case author, tags
        case chunkIndex = "chunk_index"
        case totalChunks = "total_chunks"
        case lastModified = "last_modified"
    }
}

struct SearchFilter: Equatable, Sendable {
    var sourceFilter: String?
    var minScore: Double = 0.0
    var maxResults: Int = 20
    var documentTypes: [String] = []
    var tags: [String] = []
}

// MARK: - RAG++ API Response

struct RAGSearchResponse: Codable, Sendable {
    let results: [RAGResult]
    let query: String
    let totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case results, query
        case totalResults = "total_results"
    }
}

struct RAGResult: Codable, Sendable {
    let id: String?
    let score: Double
    let content: String
    let source: String?
    let title: String?
    let metadata: [String: AnyCodableValue]?

    func toSearchResult() -> SearchResult {
        SearchResult(
            id: id.flatMap(UUID.init) ?? UUID(),
            score: score,
            snippet: content,
            source: source ?? "unknown",
            title: title ?? String(content.prefix(60)),
            metadata: SearchMetadata(
                documentType: metadata?["document_type"]?.stringValue,
                author: metadata?["author"]?.stringValue,
                tags: metadata?["tags"]?.arrayValue
            )
        )
    }
}

// MARK: - Flexible JSON value for metadata

enum AnyCodableValue: Codable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([String])
    case null

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }

    var arrayValue: [String]? {
        switch self {
        case .array(let a): return a
        default: return nil
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) { self = .string(s); return }
        if let i = try? container.decode(Int.self) { self = .int(i); return }
        if let d = try? container.decode(Double.self) { self = .double(d); return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let a = try? container.decode([String].self) { self = .array(a); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .null: try container.encodeNil()
        }
    }
}

// MARK: - Preview Data

extension SearchResult {
    static let preview = SearchResult(
        score: 0.92,
        snippet: "The semantic search architecture uses vector embeddings to find contextually relevant documents across the knowledge base.",
        source: "architecture.md",
        title: "Semantic Search Architecture"
    )

    static let previewList: [SearchResult] = [
        SearchResult(
            score: 0.95,
            snippet: "RAG++ combines retrieval-augmented generation with re-ranking to deliver precise results.",
            source: "rag-overview.md",
            title: "RAG++ Overview"
        ),
        SearchResult(
            score: 0.82,
            snippet: "Knowledge chains enable linking related concepts into coherent learning paths.",
            source: "knowledge-chains.md",
            title: "Knowledge Chain Design"
        ),
        SearchResult(
            score: 0.71,
            snippet: "Claims verification uses multiple evidence sources to establish confidence scores.",
            source: "claims.md",
            title: "Claims Verification Protocol"
        ),
        SearchResult(
            score: 0.58,
            snippet: "Ideas vault provides persistent storage for capturing and organizing creative insights.",
            source: "ideas-vault.md",
            title: "Ideas Vault Design"
        ),
    ]
}
