//
//  DocumentsListView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI
import PhotosUI

struct DocumentsListView: SwiftUI.View {

    @StateObject private var viewModel = DocumentsViewModel()
    @ObservedObject private var analytics = AnalyticsService.shared

    @SwiftUI.Binding var triggerAdd: Bool

    @State private var showingImportPicker = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingSourcePicker = false
    @State private var selectedSource: DocumentSource?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var documentToDelete: CarDocument?
    @State private var showingDeleteConfirmation = false
    @State private var documentToPreview: CarDocument?
    @State private var documentToEdit: CarDocument?
    @State private var capturedDocument: CarDocument?

    var body: some SwiftUI.View {
        Group {
            if viewModel.documents.isEmpty {
                emptyState
            } else {
                documentsList
            }
        }
        .navigationTitle(L("Documents"))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            analytics.trackScreen("documents_list_screen")
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
        .onChange(of: triggerAdd) { _, newValue in
            if newValue {
                showingSourcePicker = true
                triggerAdd = false
            }
        }
        .sheet(isPresented: $showingSourcePicker, onDismiss: {
            handleSourceSelection()
        }) {
            DocumentSourcePickerView { source in
                selectedSource = source
                showingSourcePicker = false
            }
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.pdf, .image, .jpeg, .png, .heic],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItems,
            maxSelectionCount: 1,
            matching: .images
        )
        .onChange(of: selectedPhotoItems) { _, items in
            handlePhotoSelection(items)
        }
        .fullScreenCover(isPresented: $showingCamera, onDismiss: {
            if let doc = capturedDocument {
                capturedDocument = nil
                documentToEdit = doc
            }
        }) {
            CameraView { image in
                showingCamera = false
                handleCapturedImage(image)
            }
        }
        .sheet(item: $documentToPreview) { document in
            DocumentPreviewView(document: document)
        }
        .sheet(item: $documentToEdit) { document in
            DocumentEditView(document: document) { newTitle in
                viewModel.renameDocument(document, newTitle: newTitle)
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            deleteConfirmationAlert()
        }
    }

    private var emptyState: some SwiftUI.View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "doc.text")
                    .font(.system(size: 64))
                    .foregroundColor(.gray.opacity(0.5))

                Text(L("No documents yet"))
                    .appFont(.title3)
                    .foregroundColor(.gray)

                Text(L("Add your first document"))
                    .appFont(.subheadline)
                    .foregroundColor(.gray.opacity(0.9))
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)
        }
    }

    private var documentsList: some SwiftUI.View {
        List {
            interactionHintRow
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            ForEach(viewModel.documents) { document in
                Button {
                    documentToPreview = document
                } label: {
                    DocumentRowView(document: document)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        documentToDelete = document
                        showingDeleteConfirmation = true
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }

                    Button {
                        documentToEdit = document
                    } label: {
                        Label(L("Rename"), systemImage: "pencil")
                    }
                    .tint(.orange)
                }
                .contextMenu {
                    Button {
                        documentToPreview = document
                    } label: {
                        Label(L("Preview"), systemImage: "eye")
                    }

                    Button {
                        documentToEdit = document
                    } label: {
                        Label(L("Rename"), systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        documentToDelete = document
                        showingDeleteConfirmation = true
                    } label: {
                        Label(L("Delete"), systemImage: "trash")
                    }
                }
            }

            Spacer()
                .frame(height: 80)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var interactionHintRow: some SwiftUI.View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)

            Text(L("documents.list.interaction_hint"))
                .appFont(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 4)
    }

    private func handleSourceSelection() {
        guard let source = selectedSource else { return }
        selectedSource = nil
        switch source {
        case .files:
            showingImportPicker = true
        case .photos:
            showingPhotoPicker = true
        case .camera:
            showingCamera = true
        }
    }

    private func handleFileImport(_ result: Swift.Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            viewModel.importFile(from: url, customTitle: nil)
        case .failure:
            break
        }
    }

    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        guard let item = items.first else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let fileName = "photo_\(UUID().uuidString).jpg"
                viewModel.importImageData(data, fileName: fileName, customTitle: nil, source: "photo_library")
            }
        }
        selectedPhotoItems = []
    }

    private func handleCapturedImage(_ image: UIImage?) {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        let fileName = "capture_\(UUID().uuidString).jpg"
        capturedDocument = viewModel.importImageData(data, fileName: fileName, customTitle: nil, source: "camera")
    }

    private func deleteConfirmationAlert() -> Alert {
        Alert(
            title: Text(L("Delete document?")),
            message: Text(L("Delete selected document? This action cannot be undone.")),
            primaryButton: .destructive(Text(L("Delete"))) {
                if let doc = documentToDelete {
                    viewModel.deleteDocument(doc)
                }
                documentToDelete = nil
            },
            secondaryButton: .cancel {
                documentToDelete = nil
            }
        )
    }
}

struct DocumentRowView: SwiftUI.View {

    let document: CarDocument

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: CarDocument.iconName(for: document.fileType))
                .appFont(.title2)
                .foregroundColor(CarDocument.iconColor(for: document.fileType))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .appFont(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(document.fileExtension)
                        .appFont(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(CarDocument.iconColor(for: document.fileType))
                        )

                    Text(document.formattedFileSize)
                        .appFont(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
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
