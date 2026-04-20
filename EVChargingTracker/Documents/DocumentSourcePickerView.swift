//
//  DocumentSourcePickerView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 19.03.2026.
//

import SwiftUI

struct DocumentSourcePickerView: SwiftUI.View {

    let onSelect: (DocumentSource) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some SwiftUI.View {
        NavigationStack {
            List {
                Section {
                    sourceRow(
                        icon: "folder.fill",
                        iconColor: .blue,
                        title: L("Files"),
                        description: L("document.source.files.description"),
                        source: .files
                    )

                    sourceRow(
                        icon: "photo.fill",
                        iconColor: .green,
                        title: L("Photos"),
                        description: L("document.source.photos.description"),
                        source: .photos
                    )

                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceRow(
                            icon: "camera.fill",
                            iconColor: .orange,
                            title: L("Take Photo"),
                            description: L("document.source.camera.description"),
                            source: .camera
                        )
                    }
                } footer: {
                    Text(L("document.source.supported_formats"))
                }
            }
            .navigationTitle(L("document.source.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func sourceRow(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        source: DocumentSource
    ) -> some SwiftUI.View {
        Button {
            onSelect(source)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    Text(description)
                        .appFont(.caption)
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
            }
        }
    }
}
