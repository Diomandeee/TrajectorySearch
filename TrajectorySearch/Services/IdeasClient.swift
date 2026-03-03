//
//  IdeasClient.swift
//  TrajectorySearch
//
//  Supabase CRUD client for ideas table
//

import ComposableArchitecture
import Foundation
import OpenClawCore
import OpenClawSupabase
import Supabase

struct IdeasClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Idea]
    var fetchById: @Sendable (_ id: UUID) async throws -> Idea?
    var create: @Sendable (_ idea: Idea) async throws -> Idea
    var update: @Sendable (_ idea: Idea) async throws -> Idea
    var delete: @Sendable (_ id: UUID) async throws -> Void
    var search: @Sendable (_ query: String) async throws -> [Idea]
}

// MARK: - Live Implementation

extension IdeasClient: DependencyKey {
    static let liveValue = IdeasClient(
        fetchAll: {
            let response: [Idea] = try await SupabaseManager.shared.client
                .from("ideas")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response
        },
        fetchById: { id in
            let response: [Idea] = try await SupabaseManager.shared.client
                .from("ideas")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value
            return response.first
        },
        create: { idea in
            let response: Idea = try await SupabaseManager.shared.client
                .from("ideas")
                .insert(idea)
                .select()
                .single()
                .execute()
                .value
            return response
        },
        update: { idea in
            let response: Idea = try await SupabaseManager.shared.client
                .from("ideas")
                .update(idea)
                .eq("id", value: idea.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            return response
        },
        delete: { id in
            try await SupabaseManager.shared.client
                .from("ideas")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        },
        search: { query in
            let response: [Idea] = try await SupabaseManager.shared.client
                .from("ideas")
                .select()
                .ilike("title", pattern: "%\(query)%")
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response
        }
    )

    // MARK: - Preview

    static let previewValue = IdeasClient(
        fetchAll: {
            try await Task.sleep(nanoseconds: 300_000_000)
            return Idea.previewList
        },
        fetchById: { id in
            Idea.previewList.first { $0.id == id }
        },
        create: { idea in idea },
        update: { idea in idea },
        delete: { _ in },
        search: { query in
            Idea.previewList.filter {
                $0.title.localizedCaseInsensitiveContains(query)
                || $0.description.localizedCaseInsensitiveContains(query)
            }
        }
    )

    static let testValue = IdeasClient(
        fetchAll: { Idea.previewList },
        fetchById: { _ in Idea.preview },
        create: { idea in idea },
        update: { idea in idea },
        delete: { _ in },
        search: { _ in Idea.previewList }
    )
}

// MARK: - Dependency Registration

extension DependencyValues {
    var ideasClient: IdeasClient {
        get { self[IdeasClient.self] }
        set { self[IdeasClient.self] = newValue }
    }
}
