//
//  StorageComponents.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct StorageStatsSection: SwiftUI.View {

    let stats: StorageStats

    var body: some SwiftUI.View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Storage Usage")
                    .font(.headline)

                Text(stats.formattedTotalSize)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("\(stats.fileCount) files in \(stats.folderCount) folders")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

struct FolderRow: SwiftUI.View {

    let item: StorageItem

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                if let count = item.fileCount {
                    Text("\(count) files \u{2022} \(item.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FileRow: SwiftUI.View {

    let item: StorageItem

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(item.iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(item.fileType) \u{2022} \(item.formattedSize) \u{2022} \(formatDate(item.modificationDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct InfoRow: SwiftUI.View {

    let label: String
    let value: String

    var body: some SwiftUI.View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .textSelection(.enabled)
        }
    }
}
