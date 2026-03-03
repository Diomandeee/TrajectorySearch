//
//  ClaimsClient.swift
//  TrajectorySearch
//
//  Supabase CRUD client for claims table
//

import ComposableArchitecture
import Foundation
import OpenClawCore
import OpenClawSupabase
import Supabase

struct ClaimsClient: Sendable {
    var fetchAll: @Sendable () async throws -> [Claim]
    var fetchById: @Sendable (_ id: UUID) async throws -> Claim?
    var create: @Sendable (_ claim: Claim) async throws -> Claim
    var update: @Sendable (_ claim: Claim) async throws -> Claim
    var delete: @Sendable (_ id: UUID) async throws -> Void
    var addEvidence: @Sendable (_ claimId: UUID, _ evidence: Evidence) async throws -> Claim
    var search: @Sendable (_ query: String) async throws -> [Claim]
}

// MARK: - Live Implementation

extension ClaimsClient: DependencyKey {
    static let liveValue = ClaimsClient(
        fetchAll: {
            let response: [Claim] = try await SupabaseManager.shared.client
                .from("claims")
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response
        },
        fetchById: { id in
            let response: [Claim] = try await SupabaseManager.shared.client
                .from("claims")
                .select()
                .eq("id", value: id.uuidString)
                .limit(1)
                .execute()
                .value
            return response.first
        },
        create: { claim in
            let response: Claim = try await SupabaseManager.shared.client
                .from("claims")
                .insert(claim)
                .select()
                .single()
                .execute()
                .value
            return response
        },
        update: { claim in
            let response: Claim = try await SupabaseManager.shared.client
                .from("claims")
                .update(claim)
                .eq("id", value: claim.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            return response
        },
        delete: { id in
            try await SupabaseManager.shared.client
                .from("claims")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        },
        addEvidence: { claimId, evidence in
            // Fetch the claim, append evidence, update
            let claims: [Claim] = try await SupabaseManager.shared.client
                .from("claims")
                .select()
                .eq("id", value: claimId.uuidString)
                .limit(1)
                .execute()
                .value

            guard var claim = claims.first else {
                throw ClaimsError.notFound
            }

            claim.evidence.append(evidence)
            claim.updatedAt = Date()

            let updated: Claim = try await SupabaseManager.shared.client
                .from("claims")
                .update(claim)
                .eq("id", value: claimId.uuidString)
                .select()
                .single()
                .execute()
                .value

            return updated
        },
        search: { query in
            let response: [Claim] = try await SupabaseManager.shared.client
                .from("claims")
                .select()
                .ilike("statement", pattern: "%\(query)%")
                .order("updated_at", ascending: false)
                .execute()
                .value
            return response
        }
    )

    // MARK: - Preview

    static let previewValue = ClaimsClient(
        fetchAll: {
            try await Task.sleep(nanoseconds: 300_000_000)
            return Claim.previewList
        },
        fetchById: { id in
            Claim.previewList.first { $0.id == id }
        },
        create: { claim in claim },
        update: { claim in claim },
        delete: { _ in },
        addEvidence: { claimId, evidence in
            var claim = Claim.preview
            claim.evidence.append(evidence)
            return claim
        },
        search: { query in
            Claim.previewList.filter {
                $0.statement.localizedCaseInsensitiveContains(query)
            }
        }
    )

    static let testValue = ClaimsClient(
        fetchAll: { Claim.previewList },
        fetchById: { _ in Claim.preview },
        create: { claim in claim },
        update: { claim in claim },
        delete: { _ in },
        addEvidence: { _, _ in Claim.preview },
        search: { _ in Claim.previewList }
    )
}

// MARK: - Errors

enum ClaimsError: Error, LocalizedError {
    case notFound
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .notFound: return "Claim not found"
        case .updateFailed: return "Failed to update claim"
        }
    }
}

// MARK: - Dependency Registration

extension DependencyValues {
    var claimsClient: ClaimsClient {
        get { self[ClaimsClient.self] }
        set { self[ClaimsClient.self] = newValue }
    }
}
