//
//  ClaimsView.swift
//  TrajectorySearch
//
//  Claims list with verdict badges, evidence, and confidence scores
//

import ComposableArchitecture
import SwiftUI

struct ClaimsView: View {
    @Bindable var store: StoreOf<ClaimsFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView("Loading claims...")
                } else if store.filteredClaims.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Verdict summary bar
                        verdictSummary

                        claimsList
                    }
                }
            }
            .navigationTitle("Claims")
            .searchable(
                text: Binding(
                    get: { store.searchQuery },
                    set: { store.send(.searchChanged($0)) }
                ),
                prompt: "Search claims..."
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.showNewClaim)
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Section("Verdict") {
                            Button("All Verdicts") {
                                store.send(.filterByVerdict(nil))
                            }
                            ForEach(ClaimVerdict.allCases, id: \.self) { verdict in
                                Button {
                                    store.send(.filterByVerdict(verdict))
                                } label: {
                                    Label(verdict.displayName, systemImage: verdict.icon)
                                }
                            }
                        }
                        Section("Category") {
                            Button("All Categories") {
                                store.send(.filterByCategory(nil))
                            }
                            ForEach(ClaimCategory.allCases, id: \.self) { cat in
                                Button {
                                    store.send(.filterByCategory(cat))
                                } label: {
                                    Label(cat.displayName, systemImage: cat.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { store.showingNewClaim },
                set: { newVal in if newVal { store.send(.showNewClaim) } else { store.send(.hideNewClaim) } }
            )) {
                NewClaimSheet { statement, description in
                    store.send(.createClaim(statement, description))
                } onCancel: {
                    store.send(.hideNewClaim)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - Verdict Summary

    private var verdictSummary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClaimVerdict.allCases, id: \.self) { verdict in
                    let count = store.verdictCounts[verdict] ?? 0
                    Button {
                        if store.filterVerdict == verdict {
                            store.send(.filterByVerdict(nil))
                        } else {
                            store.send(.filterByVerdict(verdict))
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: verdict.icon)
                                .font(.title3)
                                .foregroundStyle(verdictColor(verdict))

                            Text("\(count)")
                                .font(.headline.monospacedDigit())

                            Text(verdict.displayName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64, height: 70)
                        .background(
                            store.filterVerdict == verdict
                                ? verdictColor(verdict).opacity(0.15)
                                : Color.gray.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Claims List

    private var claimsList: some View {
        List {
            ForEach(store.filteredClaims) { claim in
                NavigationLink {
                    ClaimDetailView(
                        claim: claim,
                        onSetVerdict: { verdict in
                            store.send(.setVerdict(claim.id, verdict))
                        },
                        onAddEvidence: { evidence in
                            store.send(.addEvidence(claim.id, evidence))
                        },
                        onRemoveEvidence: { evidenceID in
                            store.send(.removeEvidence(claim.id, evidenceID))
                        },
                        onDelete: {
                            store.send(.deleteClaim(claim.id))
                        }
                    )
                } label: {
                    ClaimRow(claim: claim)
                }
            }
            .onDelete { indexSet in
                let claims = store.filteredClaims
                for index in indexSet {
                    store.send(.deleteClaim(claims[index].id))
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.shield")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.6))

            Text("No Claims Yet")
                .font(.title2.weight(.semibold))

            Text("Add claims to verify or falsify.\nLink evidence and track confidence.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                store.send(.showNewClaim)
            } label: {
                Label("New Claim", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }

    private func verdictColor(_ verdict: ClaimVerdict) -> Color {
        switch verdict {
        case .verified: return .green
        case .falsified: return .red
        case .partial: return .orange
        case .disputed: return .yellow
        case .unverified: return .gray
        }
    }
}

// MARK: - Claim Row

struct ClaimRow: View {
    let claim: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Verdict badge
                Image(systemName: claim.verdict.icon)
                    .font(.title3)
                    .foregroundStyle(verdictColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(claim.statement)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)

                    if !claim.description.isEmpty {
                        Text(claim.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            HStack {
                // Verdict label
                Text(claim.verdict.displayName)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(verdictColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(verdictColor)

                // Confidence
                if claim.confidence > 0 {
                    Text(String(format: "%.0f%%", claim.confidence * 100))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Evidence count
                if !claim.evidence.isEmpty {
                    Label("\(claim.evidence.count)", systemImage: "doc.text")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Tags
                if !claim.tags.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(claim.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(.gray.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var verdictColor: Color {
        switch claim.verdict {
        case .verified: return .green
        case .falsified: return .red
        case .partial: return .orange
        case .disputed: return .yellow
        case .unverified: return .gray
        }
    }
}

// MARK: - Claim Detail View

struct ClaimDetailView: View {
    let claim: Claim
    let onSetVerdict: (ClaimVerdict) -> Void
    let onAddEvidence: (Evidence) -> Void
    let onRemoveEvidence: (UUID) -> Void
    let onDelete: () -> Void

    @State private var showingAddEvidence = false
    @State private var showDeleteConfirmation = false
    @State private var newEvidenceTitle = ""
    @State private var newEvidenceContent = ""
    @State private var newEvidenceSource = ""
    @State private var newEvidenceStance: EvidenceStance = .supporting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statement
                VStack(alignment: .leading, spacing: 8) {
                    Text(claim.statement)
                        .font(.title3.weight(.bold))

                    if !claim.description.isEmpty {
                        Text(claim.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Verdict + Confidence
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verdict")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Label(claim.verdict.displayName, systemImage: claim.verdict.icon)
                            .font(.headline)
                            .foregroundStyle(verdictColor(claim.verdict))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Confidence")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(String(format: "%.0f%%", claim.confidence * 100))
                            .font(.title2.weight(.bold).monospacedDigit())
                            .foregroundStyle(claim.confidence > 0.7 ? .green : claim.confidence > 0.4 ? .orange : .red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Verdict selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Verdict")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ClaimVerdict.allCases, id: \.self) { verdict in
                                Button {
                                    onSetVerdict(verdict)
                                } label: {
                                    Label(verdict.displayName, systemImage: verdict.icon)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            claim.verdict == verdict
                                                ? verdictColor(verdict).opacity(0.2)
                                                : Color.gray.opacity(0.1),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .foregroundStyle(claim.verdict == verdict ? verdictColor(verdict) : .secondary)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Evidence
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Evidence")
                            .font(.headline)

                        Spacer()

                        if !claim.evidence.isEmpty {
                            HStack(spacing: 8) {
                                Label("\(claim.supportingCount)", systemImage: "hand.thumbsup")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Label("\(claim.contradictingCount)", systemImage: "hand.thumbsdown")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }

                        Button {
                            showingAddEvidence = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                    }

                    if claim.evidence.isEmpty {
                        Text("No evidence linked yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(claim.evidence) { evidence in
                            EvidenceCard(
                                evidence: evidence,
                                onRemove: { onRemoveEvidence(evidence.id) }
                            )
                        }
                    }
                }

                // Tags
                if !claim.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.headline)

                        FlowLayout(spacing: 8) {
                            ForEach(claim.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }

                // Delete
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Claim", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete Claim?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { onDelete() }
        }
        .sheet(isPresented: $showingAddEvidence) {
            NavigationStack {
                Form {
                    Section("Evidence") {
                        TextField("Title", text: $newEvidenceTitle)
                        TextField("Content", text: $newEvidenceContent, axis: .vertical)
                            .lineLimit(3...8)
                        TextField("Source", text: $newEvidenceSource)

                        Picker("Stance", selection: $newEvidenceStance) {
                            ForEach(EvidenceStance.allCases, id: \.self) { stance in
                                Label(stance.displayName, systemImage: stance.icon).tag(stance)
                            }
                        }
                    }
                }
                .navigationTitle("Add Evidence")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddEvidence = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let evidence = Evidence(
                                title: newEvidenceTitle,
                                content: newEvidenceContent,
                                source: newEvidenceSource,
                                stance: newEvidenceStance
                            )
                            onAddEvidence(evidence)
                            newEvidenceTitle = ""
                            newEvidenceContent = ""
                            newEvidenceSource = ""
                            newEvidenceStance = .supporting
                            showingAddEvidence = false
                        }
                        .disabled(newEvidenceTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func verdictColor(_ verdict: ClaimVerdict) -> Color {
        switch verdict {
        case .verified: return .green
        case .falsified: return .red
        case .partial: return .orange
        case .disputed: return .yellow
        case .unverified: return .gray
        }
    }
}

// MARK: - Evidence Card

struct EvidenceCard: View {
    let evidence: Evidence
    let onRemove: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: evidence.stance.icon)
                    .foregroundStyle(stanceColor)

                Text(evidence.title)
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text(String(format: "%.0f%%", evidence.strength * 100))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if !evidence.content.isEmpty {
                Text(evidence.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack {
                Label(evidence.source, systemImage: "doc")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                }
            }
        }
        .padding(12)
        .background(stanceColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(stanceColor.opacity(0.2), lineWidth: 1)
        )
        .confirmationDialog("Remove Evidence?", isPresented: $showDeleteConfirmation) {
            Button("Remove", role: .destructive) { onRemove() }
        }
    }

    private var stanceColor: Color {
        switch evidence.stance {
        case .supporting: return .green
        case .contradicting: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - New Claim Sheet

struct NewClaimSheet: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var statement = ""
    @State private var description = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Claim") {
                    TextField("Statement to verify", text: $statement)
                    TextField("Description / context", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("New Claim")
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
                        onSave(statement, description)
                        dismiss()
                    }
                    .disabled(statement.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ClaimsView(
        store: Store(initialState: ClaimsFeature.State()) {
            ClaimsFeature()
        } withDependencies: {
            $0.claimsClient = .previewValue
        }
    )
}
