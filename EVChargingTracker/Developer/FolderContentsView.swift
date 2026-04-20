//
//  FolderContentsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct FolderContentsView: SwiftUI.View {

    let folder: StorageItem

    @State private var files: [StorageItem] = []
    @State private var carName: String?
    @State private var selectedFile: StorageItem?
    @State private var showDeleteConfirmation = false
    @State private var fileToDelete: StorageItem?
    @State private var isLoading = true

    private let service = DocumentStorageService.shared
    private let carRepo: CarRepositoryProtocol? = DatabaseManager.shared.getCarRepository()

    var body: some SwiftUI.View {
        List {
            if let name = carName {
                Section {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                        Text("Car: \(name)")
                            .appFont(.subheadline)
                    }
                }
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if files.isEmpty {
                Section {
                    Text("No files in this folder")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Section {
                    ForEach(files) { file in
                        FileRow(item: file)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    fileToDelete = file
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                selectedFile = file
                            }
                    }
                }
            }
        }
        .navigationTitle(String(folder.name.prefix(12)) + (folder.name.count > 12 ? "..." : ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFile) { file in
            FileDetailView(file: file, carName: carName)
        }
        .alert("Delete file?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let file = fileToDelete {
                    deleteFile(file)
                }
            }
        } message: {
            Text("This will permanently delete the file from storage.")
        }
        .onAppear {
            loadData()
            loadCarName()
        }
    }

    private func loadData() {
        isLoading = true
        Task {
            let items = service.getContents(of: folder.url)
            let filtered = items.filter { !$0.isDirectory }
            await MainActor.run {
                files = filtered
                isLoading = false
            }
        }
    }

    private func loadCarName() {
        guard let carId = Int64(folder.name) else { return }
        let cars = carRepo?.getAllCars() ?? []
        carName = cars.first { $0.id == carId }?.name
    }

    private func deleteFile(_ file: StorageItem) {
        if service.deleteItem(at: file.url) {
            files.removeAll { $0.id == file.id }
        }
    }
}
