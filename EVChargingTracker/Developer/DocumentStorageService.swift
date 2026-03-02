//
//  DocumentStorageService.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import SwiftUI
import os
import UniformTypeIdentifiers

/// Service for browsing raw document storage (developer debugging)
final class DocumentStorageService {

    static let shared = DocumentStorageService()

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "DocumentStorageService", category: "Storage")

    private init() {}

    var rootDirectory: URL {
        DocumentService.shared.documentsDirectoryURL
    }

    func getContents(of directory: URL) -> [StorageItem] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .creationDateKey
                ],
                options: [.skipsHiddenFiles]
            )

            return contents.compactMap { url in
                let resourceValues = try? url.resourceValues(forKeys: [
                    .isDirectoryKey,
                    .fileSizeKey,
                    .contentModificationDateKey,
                    .creationDateKey
                ])

                guard let isDirectory = resourceValues?.isDirectory else { return nil }
                let size = resourceValues?.fileSize ?? 0
                let modificationDate = resourceValues?.contentModificationDate ?? Date()

                var fileCount: Int?
                if isDirectory {
                    fileCount = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil).count
                }

                return StorageItem(
                    url: url,
                    name: url.lastPathComponent,
                    isDirectory: isDirectory,
                    size: Int64(size),
                    modificationDate: modificationDate,
                    fileCount: fileCount
                )
            }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            logger.error("Failed to get contents of directory: \(directory.path), error: \(error.localizedDescription)")
            return []
        }
    }

    func getStorageStats() -> StorageStats {
        let allContents = getContents(of: rootDirectory)
        let directories = allContents.filter { $0.isDirectory }
        let files = allContents.filter { !$0.isDirectory }

        var totalSize = Int64(0)
        var fileCount = 0

        for directory in directories {
            if let dirSize = calculateDirectorySize(at: directory.url) {
                totalSize += dirSize
            }
            fileCount += directory.fileCount ?? 0
        }

        for file in files {
            totalSize += file.size
            fileCount += 1
        }

        return StorageStats(
            totalSize: totalSize,
            fileCount: fileCount,
            folderCount: directories.count
        )
    }

    func deleteItem(at url: URL) -> Bool {
        let root = rootDirectory.standardizedFileURL.path
        let target = url.standardizedFileURL.path
        guard target.hasPrefix(root) else {
            logger.error("Attempted to delete item outside root directory: \(target)")
            return false
        }

        do {
            try fileManager.removeItem(at: url)
            logger.info("Deleted item at: \(url.path)")
            return true
        } catch {
            logger.error("Failed to delete item at \(url.path): \(error.localizedDescription)")
            return false
        }
    }

    func getFileAttributes(at url: URL) -> FileAttributes? {
        let resourceValues = try? url.resourceValues(forKeys: [
            .nameKey,
            .typeIdentifierKey,
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])

        guard let name = resourceValues?.name,
              let typeIdentifier = resourceValues?.typeIdentifier else { return nil }

        let typeName = UTType(typeIdentifier)?.localizedDescription ?? typeIdentifier

        return FileAttributes(
            name: name,
            path: url.path,
            size: resourceValues?.fileSize ?? 0,
            type: typeName,
            creationDate: resourceValues?.creationDate,
            modificationDate: resourceValues?.contentModificationDate
        )
    }

    private func calculateDirectorySize(at url: URL) -> Int64? {
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])
        var totalSize = Int64(0)

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues?.fileSize {
                totalSize += Int64(fileSize)
            }
        }

        return totalSize
    }
}

struct StorageItem: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let fileCount: Int?

    var icon: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        return CarDocument.iconName(for: ext)
    }

    var iconColor: Color {
        if isDirectory { return .blue }
        let ext = (name as NSString).pathExtension.lowercased()
        return CarDocument.iconColor(for: ext)
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var fileType: String {
        if isDirectory { return "Folder" }
        let ext = (name as NSString).pathExtension.uppercased()
        return ext.isEmpty ? "Unknown" : "\(ext) File"
    }
}

struct StorageStats {
    let totalSize: Int64
    let fileCount: Int
    let folderCount: Int

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

struct FileAttributes {
    let name: String
    let path: String
    let size: Int
    let type: String
    let creationDate: Date?
    let modificationDate: Date?
}
