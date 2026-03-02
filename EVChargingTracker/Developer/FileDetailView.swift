//
//  FileDetailView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI
import QuickLook

struct FileDetailView: SwiftUI.View {

    let file: StorageItem
    let carName: String?

    @Environment(\.dismiss) private var dismiss
    @State private var attributes: FileAttributes?
    @State private var quickLookURL: URL?
    @State private var showShareSheet = false
    @State private var showDeleteConfirmation = false

    private let service = DocumentStorageService.shared

    var body: some SwiftUI.View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: file.icon)
                            .font(.system(size: 48))
                            .foregroundColor(file.iconColor)
                        Text(file.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            }

            Section(header: Text("File Info")) {
                InfoRow(label: "Type", value: attributes?.type ?? "Unknown")
                InfoRow(label: "Size", value: file.formattedSize)
                if let created = attributes?.creationDate {
                    InfoRow(label: "Created", value: formatDate(created))
                }
                if let modified = attributes?.modificationDate {
                    InfoRow(label: "Modified", value: formatDate(modified))
                }
                InfoRow(label: "Path", value: attributes?.path ?? file.url.path)
            }

            Section {
                Button {
                    quickLookURL = file.url
                } label: {
                    Label("Quick Look", systemImage: "eye")
                }

                Button {
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .quickLookPreview($quickLookURL)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [file.url])
        }
        .alert("Delete file?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteFile()
                dismiss()
            }
        } message: {
            Text("This will permanently delete the file from storage.")
        }
        .onAppear {
            attributes = service.getFileAttributes(at: file.url)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func deleteFile() {
        _ = service.deleteItem(at: file.url)
    }
}
