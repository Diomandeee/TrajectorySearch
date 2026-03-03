//
//  ClaimsFeature.swift
//  TrajectorySearch
//
//  TCA reducer: Claims management, verdict tracking, evidence linking
//

import ComposableArchitecture
import Foundation

@Reducer
struct ClaimsFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var claims: IdentifiedArrayOf<Claim> = []
        var isLoading: Bool = false
        var errorMessage: String?
        var searchQuery: String = ""
        var selectedClaimID: UUID?
        var editingClaim: Claim?
        var showingNewClaim: Bool = false
        var showingAddEvidence: Bool = false
        var filterVerdict: ClaimVerdict?
        var filterCategory: ClaimCategory?

        var filteredClaims: IdentifiedArrayOf<Claim> {
            var filtered = claims.elements

            if !searchQuery.isEmpty {
                filtered = filtered.filter {
                    $0.statement.localizedCaseInsensitiveContains(searchQuery)
                    || $0.description.localizedCaseInsensitiveContains(searchQuery)
                    || $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
                }
            }

            if let verdict = filterVerdict {
                filtered = filtered.filter { $0.verdict == verdict }
            }

            if let category = filterCategory {
                filtered = filtered.filter { $0.category == category }
            }

            filtered.sort { $0.updatedAt > $1.updatedAt }
            return IdentifiedArrayOf(uniqueElements: filtered)
        }

        var selectedClaim: Claim? {
            guard let id = selectedClaimID else { return nil }
            return claims[id: id]
        }

        var verdictCounts: [ClaimVerdict: Int] {
            var counts: [ClaimVerdict: Int] = [:]
            for verdict in ClaimVerdict.allCases {
                counts[verdict] = claims.filter { $0.verdict == verdict }.count
            }
            return counts
        }
    }

    // MARK: - Action

    enum Action: Sendable {
        // Lifecycle
        case onAppear
        case loadClaims
        case claimsLoaded([Claim])
        case loadFailed(String)

        // CRUD
        case createClaim(String, String)
        case claimCreated(Claim)
        case updateClaim(Claim)
        case claimUpdated(Claim)
        case deleteClaim(UUID)
        case claimDeleted(UUID)

        // Verdict
        case setVerdict(UUID, ClaimVerdict)
        case setConfidence(UUID, Double)

        // Evidence
        case addEvidence(UUID, Evidence)
        case removeEvidence(UUID, UUID)
        case showAddEvidence
        case hideAddEvidence

        // Selection & editing
        case selectClaim(UUID?)
        case editClaim(Claim)
        case cancelEdit
        case showNewClaim
        case hideNewClaim

        // Editing fields
        case updateEditStatement(String)
        case updateEditDescription(String)
        case updateEditCategory(ClaimCategory)
        case addEditTag(String)
        case removeEditTag(String)

        // Search & filter
        case searchChanged(String)
        case filterByVerdict(ClaimVerdict?)
        case filterByCategory(ClaimCategory?)

        // Error
        case operationFailed(String)
    }

    // MARK: - Dependencies

    @Dependency(\.claimsClient) var claimsClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date) var date

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // MARK: Lifecycle

            case .onAppear:
                return .send(.loadClaims)

            case .loadClaims:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    let claims = try await claimsClient.fetchAll()
                    await send(.claimsLoaded(claims))
                } catch: { error, send in
                    await send(.loadFailed(error.localizedDescription))
                }

            case .claimsLoaded(let claims):
                state.isLoading = false
                state.claims = IdentifiedArrayOf(uniqueElements: claims)
                return .none

            case .loadFailed(let message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            // MARK: CRUD

            case .createClaim(let statement, let description):
                let claim = Claim(
                    id: uuid(),
                    statement: statement,
                    description: description,
                    createdAt: date.now,
                    updatedAt: date.now
                )
                return .run { send in
                    let created = try await claimsClient.create(claim)
                    await send(.claimCreated(created))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .claimCreated(let claim):
                state.claims.insert(claim, at: 0)
                state.showingNewClaim = false
                state.editingClaim = nil
                return .none

            case .updateClaim(let claim):
                return .run { send in
                    let updated = try await claimsClient.update(claim)
                    await send(.claimUpdated(updated))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .claimUpdated(let claim):
                state.claims[id: claim.id] = claim
                state.editingClaim = nil
                return .none

            case .deleteClaim(let id):
                return .run { send in
                    try await claimsClient.delete(id)
                    await send(.claimDeleted(id))
                } catch: { error, send in
                    await send(.operationFailed(error.localizedDescription))
                }

            case .claimDeleted(let id):
                state.claims.remove(id: id)
                if state.selectedClaimID == id {
                    state.selectedClaimID = nil
                }
                return .none

            // MARK: Verdict

            case .setVerdict(let id, let verdict):
                if var claim = state.claims[id: id] {
                    claim.verdict = verdict
                    claim.reviewedAt = date.now
                    claim.updatedAt = date.now
                    state.claims[id: id] = claim
                    return .send(.updateClaim(claim))
                }
                return .none

            case .setConfidence(let id, let confidence):
                if var claim = state.claims[id: id] {
                    claim.confidence = confidence
                    claim.updatedAt = date.now
                    state.claims[id: id] = claim
                }
                return .none

            // MARK: Evidence

            case .addEvidence(let claimID, let evidence):
                if var claim = state.claims[id: claimID] {
                    claim.evidence.append(evidence)
                    claim.updatedAt = date.now
                    state.claims[id: claimID] = claim
                    state.showingAddEvidence = false
                }
                return .none

            case .removeEvidence(let claimID, let evidenceID):
                if var claim = state.claims[id: claimID] {
                    claim.evidence.removeAll { $0.id == evidenceID }
                    claim.updatedAt = date.now
                    state.claims[id: claimID] = claim
                }
                return .none

            case .showAddEvidence:
                state.showingAddEvidence = true
                return .none

            case .hideAddEvidence:
                state.showingAddEvidence = false
                return .none

            // MARK: Selection & Editing

            case .selectClaim(let id):
                state.selectedClaimID = id
                return .none

            case .editClaim(let claim):
                state.editingClaim = claim
                return .none

            case .cancelEdit:
                state.editingClaim = nil
                return .none

            case .showNewClaim:
                state.showingNewClaim = true
                state.editingClaim = Claim(
                    id: uuid(),
                    statement: "",
                    createdAt: date.now,
                    updatedAt: date.now
                )
                return .none

            case .hideNewClaim:
                state.showingNewClaim = false
                state.editingClaim = nil
                return .none

            // MARK: Editing Fields

            case .updateEditStatement(let statement):
                state.editingClaim?.statement = statement
                return .none

            case .updateEditDescription(let description):
                state.editingClaim?.description = description
                return .none

            case .updateEditCategory(let category):
                state.editingClaim?.category = category
                return .none

            case .addEditTag(let tag):
                let trimmed = tag.trimmingCharacters(in: .whitespaces).lowercased()
                if !trimmed.isEmpty, !(state.editingClaim?.tags.contains(trimmed) ?? false) {
                    state.editingClaim?.tags.append(trimmed)
                }
                return .none

            case .removeEditTag(let tag):
                state.editingClaim?.tags.removeAll { $0 == tag }
                return .none

            // MARK: Search & Filter

            case .searchChanged(let query):
                state.searchQuery = query
                return .none

            case .filterByVerdict(let verdict):
                state.filterVerdict = verdict
                return .none

            case .filterByCategory(let category):
                state.filterCategory = category
                return .none

            // MARK: Error

            case .operationFailed(let message):
                state.errorMessage = message
                return .none
            }
        }
    }
}
