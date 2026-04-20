//
//  IdeaRowView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct IdeaRowView: SwiftUI.View {

    let idea: Idea

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 6) {
            Text(idea.title)
                .appFont(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            if let host = idea.hostName {
                Label(host, systemImage: "link")
                    .appFont(.subheadline)
                    .foregroundColor(.blue)
            }

            if let description = idea.descriptionText, !description.isEmpty {
                Text(description)
                    .appFont(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
