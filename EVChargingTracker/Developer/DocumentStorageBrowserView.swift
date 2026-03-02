//
//  DocumentStorageBrowserView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct DocumentStorageBrowserView: SwiftUI.View {

    @Environment(\.dismiss) private var dismiss
    @State private var storageStats: StorageStats?
    @State private var folders: [StorageItem] = []
    @State private var rootFiles: [StorageItem] = []
    @State private var isLoading = true

    private let service = DocumentStorageService.shared

    var body: some SwiftUI.View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if let stats = storageStats {
                            StorageStatsSection(stats: stats)
                        }

                        if !folders.isEmpty {
                            Section(header: Text("Folders")) {
                                ForEach(folders) { folder in
                                    NavigationLink(destination: FolderContentsView(folder: folder)) {
                                        FolderRow(item: folder)
                                    }
                                }
                            }
                        }

                        if !rootFiles.isEmpty {
                            Section(header: Text("Root Files")) {
                                ForEach(rootFiles) { file in
                                    FileRow(item: file)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                deleteFile(file)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }

                        if folders.isEmpty && rootFiles.isEmpty {
                            Section {
                                Text("No files in document storage")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .refreshable {
                        loadData()
                    }
                }
            }
            .navigationTitle("Document Storage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                loadData()
            }
        }
    }

    private func loadData() {
        isLoading = true
        storageStats = service.getStorageStats()
        let items = service.getContents(of: service.rootDirectory)
        folders = items.filter { $0.isDirectory }
        rootFiles = items.filter { !$0.isDirectory }
        isLoading = false
    }

    private func deleteFile(_ file: StorageItem) {
        _ = service.deleteItem(at: file.url)
        loadData()
    }
}
