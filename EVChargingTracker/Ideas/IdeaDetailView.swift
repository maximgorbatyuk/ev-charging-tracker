//
//  IdeaDetailView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.03.2026.
//

import SwiftUI

struct IdeaDetailView: SwiftUI.View {

    let idea: Idea
    let onEdit: (Idea) -> Void
    let onDelete: (Idea) -> Void

    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    private let analytics = AnalyticsService.shared

    @State private var showingDeleteConfirmation = false

    var body: some SwiftUI.View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    detailsSection
                    actionsSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(L("Idea Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Close")) {
                        dismiss()
                    }
                }
            }
            .alert(L("Delete idea?"), isPresented: $showingDeleteConfirmation) {
                Button(L("Cancel"), role: .cancel) {}
                Button(L("Delete"), role: .destructive) {
                    analytics.trackEvent("idea_deleted_from_details", properties: [
                        "screen": "idea_details_screen"
                    ])
                    onDelete(idea)
                    dismiss()
                }
            } message: {
                Text(L("Delete selected idea? This action cannot be undone."))
            }
            .onAppear {
                analytics.trackScreen("idea_details_screen")
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Title"))
                    .appFont(.caption)
                    .foregroundColor(.gray)
                Text(idea.title)
                    .appFont(.title2)
                    .fontWeight(.semibold)
            }

            Divider()

            // URL
            if let urlString = idea.url, !urlString.isEmpty, let url = URL(string: urlString),
               let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("URL"))
                        .appFont(.caption)
                        .foregroundColor(.gray)

                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "link")
                                .appFont(.subheadline)
                            Text(idea.hostName ?? urlString)
                                .appFont(.body)
                                .lineLimit(1)
                        }
                        .foregroundColor(.blue)
                    }
                }
                Divider()
            }

            // Description
            if let description = idea.descriptionText, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Description"))
                        .appFont(.caption)
                        .foregroundColor(.gray)
                    Text(description)
                        .appFont(.body)
                }
                Divider()
            }

            // Created at
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Created"))
                    .appFont(.caption)
                    .foregroundColor(.gray)
                Text(idea.createdAt.formatted(as: "yyyy-MM-dd HH:mm"))
                    .appFont(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Updated at
            if abs(idea.updatedAt.timeIntervalSince(idea.createdAt)) > 1.0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Updated"))
                        .appFont(.caption)
                        .foregroundColor(.gray)
                    Text(idea.updatedAt.formatted(as: "yyyy-MM-dd HH:mm"))
                        .appFont(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
    }

    // MARK: - Actions Section

    private var actionsSection: some SwiftUI.View {
        HStack(spacing: 16) {
            actionButton(
                icon: "pencil",
                title: L("Edit"),
                color: .orange
            ) {
                analytics.trackEvent("idea_edit_from_details", properties: [
                    "screen": "idea_details_screen"
                ])
                onEdit(idea)
                dismiss()
            }

            actionButton(
                icon: "trash",
                title: L("Delete"),
                color: .red
            ) {
                showingDeleteConfirmation = true
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
        )
    }

    private func actionButton(
        icon: String,
        title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some SwiftUI.View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .appFont(.title2)
                Text(title)
                    .appFont(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundColor(color)
        }
        .buttonStyle(.plain)
    }
}
