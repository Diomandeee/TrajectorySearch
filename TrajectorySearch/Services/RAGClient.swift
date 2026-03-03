//
//  RAGClient.swift
//  TrajectorySearch
//
//  URLSession client for RAG++ semantic search API at :8000
//  Proxied through the gateway for auth/routing
//

import ComposableArchitecture
import Foundation
import OpenClawCore

struct RAGClient: Sendable {
    var search: @Sendable (_ query: String, _ filter: SearchFilter) async throws -> [SearchResult]
    var searchHistory: @Sendable () async -> [String]
    var clearHistory: @Sendable () async -> Void
}

// MARK: - Live Implementation

extension RAGClient: DependencyKey {
    static let liveValue = RAGClient(
        search: { query, filter in
            let host = OpenClawConfig.gatewayHost
            let baseURL = "http://\(host):8000"

            var urlComponents = URLComponents(string: "\(baseURL)/search")!
            urlComponents.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(filter.maxResults)),
            ]
            if filter.minScore > 0 {
                urlComponents.queryItems?.append(
                    URLQueryItem(name: "min_score", value: String(filter.minScore))
                )
            }
            if let source = filter.sourceFilter, !source.isEmpty {
                urlComponents.queryItems?.append(
                    URLQueryItem(name: "source", value: source)
                )
            }
            if !filter.documentTypes.isEmpty {
                urlComponents.queryItems?.append(
                    URLQueryItem(name: "doc_types", value: filter.documentTypes.joined(separator: ","))
                )
            }
            if !filter.tags.isEmpty {
                urlComponents.queryItems?.append(
                    URLQueryItem(name: "tags", value: filter.tags.joined(separator: ","))
                )
            }

            guard let url = urlComponents.url else {
                throw RAGError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.timeoutInterval = 30

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw RAGError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8) ?? ""
                throw RAGError.httpError(httpResponse.statusCode, body)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            // Try parsing as RAGSearchResponse first, then fall back to raw array
            if let ragResponse = try? decoder.decode(RAGSearchResponse.self, from: data) {
                return ragResponse.results.map { $0.toSearchResult() }
            }

            if let rawResults = try? decoder.decode([RAGResult].self, from: data) {
                return rawResults.map { $0.toSearchResult() }
            }

            throw RAGError.decodingFailed
        },
        searchHistory: {
            UserDefaults.standard.stringArray(forKey: "rag_search_history") ?? []
        },
        clearHistory: {
            UserDefaults.standard.removeObject(forKey: "rag_search_history")
        }
    )

    // MARK: - Preview / Test

    static let previewValue = RAGClient(
        search: { _, _ in
            try await Task.sleep(nanoseconds: 500_000_000)
            return SearchResult.previewList
        },
        searchHistory: {
            ["knowledge chains", "semantic search", "vector embeddings", "RAG architecture"]
        },
        clearHistory: {}
    )

    static let testValue = RAGClient(
        search: { _, _ in SearchResult.previewList },
        searchHistory: { [] },
        clearHistory: {}
    )
}

// MARK: - Errors

enum RAGError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid RAG++ URL"
        case .invalidResponse: return "Invalid response from RAG++"
        case let .httpError(code, body): return "RAG++ HTTP \(code): \(body.prefix(200))"
        case .decodingFailed: return "Failed to decode RAG++ response"
        case .timeout: return "RAG++ request timed out"
        }
    }
}

// MARK: - Search History Helper

enum SearchHistoryManager {
    private static let key = "rag_search_history"
    private static let maxHistory = 50

    static func addQuery(_ query: String) {
        var history = UserDefaults.standard.stringArray(forKey: key) ?? []
        // Remove duplicate if exists
        history.removeAll { $0 == query }
        // Add to front
        history.insert(query, at: 0)
        // Trim
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }
        UserDefaults.standard.set(history, forKey: key)
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var ragClient: RAGClient {
        get { self[RAGClient.self] }
        set { self[RAGClient.self] = newValue }
    }
}
