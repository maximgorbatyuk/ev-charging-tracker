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
    @State private var showingSourceChooser = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var documentToDelete: CarDocument?
    @State private var showingDeleteConfirmation = false
    @State private var documentToPreview: CarDocument?
    @State private var documentToRename: CarDocument?
    @State private var renameText: String = ""

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
                showingSourceChooser = true
                triggerAdd = false
            }
        }
        .confirmationDialog(L("Import from"), isPresented: $showingSourceChooser, titleVisibility: .visible) {
            Button(L("Files")) {
                showingImportPicker = true
            }
            Button(L("Photos")) {
                showingPhotoPicker = true
            }
            Button(L("Cancel"), role: .cancel) {}
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
        .sheet(item: $documentToPreview) { document in
            DocumentPreviewView(document: document)
        }
        .alert(L("Rename document"), isPresented: .constant(documentToRename != nil)) {
            TextField(L("New title"), text: $renameText)
            Button(L("Save")) {
                if let doc = documentToRename {
                    viewModel.renameDocument(doc, newTitle: renameText)
                }
                documentToRename = nil
            }
            Button(L("Cancel"), role: .cancel) {
                documentToRename = nil
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
                    .font(.title3)
                    .foregroundColor(.gray)

                Text(L("Add your first document"))
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.9))
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            .multilineTextAlignment(.center)
        }
    }

    private var documentsList: some SwiftUI.View {
        List {
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
                        renameText = document.customTitle ?? ""
                        documentToRename = document
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
                        renameText = document.customTitle ?? ""
                        documentToRename = document
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
                let fileName = "photo_\(Int(Date().timeIntervalSince1970)).jpg"
                viewModel.importImageData(data, fileName: fileName, customTitle: nil)
            }
        }
        selectedPhotoItems = []
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
                .font(.title2)
                .foregroundColor(CarDocument.iconColor(for: document.fileType))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(document.fileExtension)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(CarDocument.iconColor(for: document.fileType))
                        )

                    Text(document.formattedFileSize)
                        .font(.caption)
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
