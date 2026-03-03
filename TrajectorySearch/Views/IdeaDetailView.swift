//
//  IdeaDetailView.swift
//  TrajectorySearch
//
//  Full idea view with editor, tags, status, and metadata
//

import SwiftUI

struct IdeaDetailView: View {
    let idea: Idea
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onStatusChange: (IdeaStatus) -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection

                Divider()

                // Description
                if !idea.description.isEmpty {
                    descriptionSection
                }

                // Tags
                if !idea.tags.isEmpty {
                    tagsSection
                }

                // Metadata
                metadataSection

                // Status control
                statusSection

                // Notes
                if let notes = idea.notes, !notes.isEmpty {
                    notesSection(notes)
                }

                // Links
                if !idea.links.isEmpty {
                    linksSection
                }

                // Actions
                actionsSection
            }
            .padding()
        }
        .navigationTitle(idea.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .confirmationDialog("Delete Idea?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: idea.category.icon)
                        .foregroundStyle(.blue)
                    Text(idea.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(idea.title)
                    .font(.title2.weight(.bold))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                priorityBadge
                statusBadge
            }
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            Text(idea.priority.displayName)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.1), in: Capsule())
    }

    private var statusBadge: some View {
        Label(idea.status.displayName, systemImage: idea.status.icon)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.1), in: Capsule())
    }

    private var priorityColor: Color {
        switch idea.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            Text(idea.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(idea.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1), in: Capsule())
                }
            }
        }
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetadataCard(label: "Created", value: idea.createdAt.formatted(date: .abbreviated, time: .shortened))
                MetadataCard(label: "Updated", value: idea.updatedAt.formatted(date: .abbreviated, time: .shortened))
                if let source = idea.source {
                    MetadataCard(label: "Source", value: source)
                }
                MetadataCard(label: "Links", value: "\(idea.links.count)")
            }
        }
    }

    // MARK: - Status Control

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(IdeaStatus.allCases, id: \.self) { status in
                        Button {
                            onStatusChange(status)
                        } label: {
                            Label(status.displayName, systemImage: status.icon)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    idea.status == status
                                        ? Color.blue.opacity(0.2)
                                        : Color.gray.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: 8)
                                )
                                .foregroundStyle(idea.status == status ? .blue : .secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)

            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Links")
                .font(.headline)

            ForEach(idea.links) { link in
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.blue)
                    Text(link.linkType.displayName)
                        .font(.subheadline)
                    if let label = link.label {
                        Text("- \(label)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete Idea", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 16)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = currentY + lineHeight
        }

        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}

// MARK: - Metadata Card

struct MetadataCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        IdeaDetailView(
            idea: Idea.preview,
            onEdit: {},
            onDelete: {},
            onStatusChange: { _ in }
        )
    }
}
