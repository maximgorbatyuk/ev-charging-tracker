//
//  DocumentService.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import os
import UniformTypeIdentifiers

class DocumentService {

    static let shared = DocumentService()

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "DocumentService", category: "Storage")

    private init() {}

    var documentsDirectoryURL: URL {
        AppGroupContainer.containerURL.appendingPathComponent("CarDocuments", isDirectory: true)
    }

    func ensureDirectoryExists() {
        let url = documentsDirectoryURL
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                logger.error("Failed to create documents directory: \(error)")
            }
        }
    }

    func saveFile(data: Data, fileName: String, carId: Int64) -> URL? {
        ensureDirectoryExists()

        let carDirectory = documentsDirectoryURL
            .appendingPathComponent("\(carId)", isDirectory: true)

        if !fileManager.fileExists(atPath: carDirectory.path) {
            do {
                try fileManager.createDirectory(at: carDirectory, withIntermediateDirectories: true)
            } catch {
                logger.error("Failed to create car directory: \(error)")
                return nil
            }
        }

        let uniqueName = generateUniqueFileName(original: fileName)
        let destinationURL = carDirectory.appendingPathComponent(uniqueName)

        do {
            try data.write(to: destinationURL)
            return destinationURL
        } catch {
            logger.error("Failed to save document: \(error)")
            return nil
        }
    }

    func copyFile(from sourceURL: URL, fileName: String, carId: Int64) -> URL? {
        ensureDirectoryExists()

        let carDirectory = documentsDirectoryURL
            .appendingPathComponent("\(carId)", isDirectory: true)

        if !fileManager.fileExists(atPath: carDirectory.path) {
            do {
                try fileManager.createDirectory(at: carDirectory, withIntermediateDirectories: true)
            } catch {
                logger.error("Failed to create car directory: \(error)")
                return nil
            }
        }

        let uniqueName = generateUniqueFileName(original: fileName)
        let destinationURL = carDirectory.appendingPathComponent(uniqueName)

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            logger.error("Failed to copy document: \(error)")
            return nil
        }
    }

    func deleteFile(at path: String) {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: url.path) else { return }

        do {
            try fileManager.removeItem(at: url)
        } catch {
            logger.error("Failed to delete document: \(error)")
        }
    }

    func deleteCarDocuments(carId: Int64) {
        let carDirectory = documentsDirectoryURL
            .appendingPathComponent("\(carId)", isDirectory: true)

        guard fileManager.fileExists(atPath: carDirectory.path) else { return }

        do {
            try fileManager.removeItem(at: carDirectory)
        } catch {
            logger.error("Failed to delete car documents directory: \(error)")
        }
    }

    func deleteAllDocumentFiles() {
        let url = documentsDirectoryURL
        guard fileManager.fileExists(atPath: url.path) else { return }

        do {
            try fileManager.removeItem(at: url)
            logger.info("Deleted all document files")
        } catch {
            logger.error("Failed to delete all document files: \(error)")
        }
    }

    // MARK: - Temporary Backup for Safe Import

    private var temporaryDocumentBackupURL: URL {
        AppGroupContainer.containerURL.appendingPathComponent("CarDocuments_backup", isDirectory: true)
    }

    func moveDocumentsToTemporaryBackup() {
        let source = documentsDirectoryURL
        let destination = temporaryDocumentBackupURL

        // Clean up any stale temp backup first
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }

        guard fileManager.fileExists(atPath: source.path) else { return }

        do {
            try fileManager.moveItem(at: source, to: destination)
            logger.info("Moved document files to temporary backup")
        } catch {
            logger.error("Failed to move documents to temporary backup: \(error)")
        }
    }

    func restoreDocumentsFromTemporaryBackup() {
        let source = temporaryDocumentBackupURL
        let destination = documentsDirectoryURL

        guard fileManager.fileExists(atPath: source.path) else {
            logger.warning("No temporary document backup to restore from")
            return
        }

        // Remove any partially-imported files
        if fileManager.fileExists(atPath: destination.path) {
            try? fileManager.removeItem(at: destination)
        }

        do {
            try fileManager.moveItem(at: source, to: destination)
            logger.info("Restored document files from temporary backup")
        } catch {
            logger.error("Failed to restore documents from temporary backup: \(error)")
        }
    }

    func removeTemporaryDocumentBackup() {
        let url = temporaryDocumentBackupURL
        guard fileManager.fileExists(atPath: url.path) else { return }

        do {
            try fileManager.removeItem(at: url)
            logger.info("Removed temporary document backup")
        } catch {
            logger.error("Failed to remove temporary document backup: \(error)")
        }
    }

    func fileSize(at path: String) -> Int64 {
        do {
            let attrs = try fileManager.attributesOfItem(atPath: path)
            return attrs[.size] as? Int64 ?? 0
        } catch {
            logger.error("Failed to get file size: \(error)")
            return 0
        }
    }

    func detectFileType(fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        if let utType = UTType(filenameExtension: ext) {
            if utType.conforms(to: .pdf) { return "pdf" }
            if utType.conforms(to: .image) { return ext.isEmpty ? "image" : ext }
        }
        return ext.isEmpty ? "unknown" : ext
    }

    func allStoredFiles() -> [URL] {
        guard fileManager.fileExists(atPath: documentsDirectoryURL.path) else { return [] }

        var result: [URL] = []
        if let enumerator = fileManager.enumerator(
            at: documentsDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                let isFile = (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
                if isFile {
                    result.append(fileURL)
                }
            }
        }
        return result
    }

    private func sanitizeFileName(_ name: String) -> String {
        (name as NSString).lastPathComponent
    }

    private func generateUniqueFileName(original: String) -> String {
        let sanitized = sanitizeFileName(original)
        let ext = (sanitized as NSString).pathExtension
        let name = (sanitized as NSString).deletingPathExtension
        let timestamp = Int(Date().timeIntervalSince1970)
        if ext.isEmpty {
            return "\(name)_\(timestamp)"
        }
        return "\(name)_\(timestamp).\(ext)"
    }
}
