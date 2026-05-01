//
//  DocumentEditView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.03.2026.
//

import SwiftUI

struct DocumentEditView: SwiftUI.View {

    let document: CarDocument
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var customName: String

    init(document: CarDocument, onSave: @escaping (String) -> Void) {
        self.document = document
        self.onSave = onSave
        _customName = State(initialValue: document.customTitle ?? "")
    }

    var body: some SwiftUI.View {
        NavigationStack {
            Form {
                Section(header: Text(L("Rename document"))) {
                    TextField(L("New title"), text: $customName)
                }

                Section(header: Text(L("share.section.document_info"))) {
                    metadataRow(title: L("document.file_size"), value: document.formattedFileSize)
                        .listRowBackground(Color(uiColor: .systemGroupedBackground))
                        .listRowSeparator(.hidden)

                    metadataRow(title: L("Created"), value: formattedDate(document.createdAt))
                        .listRowBackground(Color(uiColor: .systemGroupedBackground))
                        .listRowSeparator(.hidden)

                    metadataRow(title: L("Updated"), value: formattedDate(document.updatedAt))
                        .listRowBackground(Color(uiColor: .systemGroupedBackground))
                        .listRowSeparator(.hidden)

                    metadataRow(title: L("document.file_path"), value: document.filePath ?? L("File not found"))
                        .listRowBackground(Color(uiColor: .systemGroupedBackground))
                        .listRowSeparator(.hidden)
                }
            }
            .navigationTitle(L("Rename document"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Save")) {
                        onSave(customName)
                        dismiss()
                    }
                }
            }
        }
    }

    private func metadataRow(title: String, value: String) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .appFont(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .appFont(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}
