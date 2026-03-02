//
//  InputParser.swift
//  ShareExtension
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import UniformTypeIdentifiers
import os

class InputParser {

    private let logger = Logger(subsystem: "ShareExtension", category: "InputParser")

    /// Share Extensions have ~120MB memory limit. Cap file reads well below that.
    private static let maxFileSizeBytes = 50 * 1024 * 1024 // 50 MB

    /// Parses NSExtensionItem attachments into a SharedInput.
    /// Priority: URL → plain text → image → file.
    func parse(inputItems: [NSExtensionItem]) async -> SharedInput? {
        var suggestedTitle: String?

        for item in inputItems {
            // Collect title from attributedContentText
            if let contentText = item.attributedContentText?.string,
               !contentText.isEmpty {
                suggestedTitle = contentText
            }

            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Try URL first
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let input = await extractURL(from: provider, suggestedTitle: suggestedTitle) {
                        return input
                    }
                }

                // Then plain text
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let input = await extractText(from: provider, suggestedTitle: suggestedTitle) {
                        return input
                    }
                }

                // Then image
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let input = await extractFileData(from: provider, typeIdentifier: UTType.image.identifier, suggestedTitle: suggestedTitle) {
                        return input
                    }
                }

                // Then general file (PDF, etc.)
                if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    if let input = await extractFileData(from: provider, typeIdentifier: UTType.data.identifier, suggestedTitle: suggestedTitle) {
                        return input
                    }
                }
            }
        }

        logger.info("No supported content found in shared items")
        return nil
    }

    // MARK: - Extraction helpers

    private func extractURL(from provider: NSItemProvider, suggestedTitle: String?) async -> SharedInput? {
        do {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.url.identifier)
            if let url = item as? URL {
                logger.debug("Extracted URL: \(url.absoluteString)")
                return SharedInput(
                    kind: .link,
                    url: url,
                    text: nil,
                    suggestedTitle: suggestedTitle ?? url.host
                )
            }
        } catch {
            logger.warning("Failed to extract URL: \(error.localizedDescription)")
        }
        return nil
    }

    private func extractText(from provider: NSItemProvider, suggestedTitle: String?) async -> SharedInput? {
        do {
            let item = try await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier)
            if let text = item as? String, !text.isEmpty {
                // Check if text is actually a URL
                if let url = URL(string: text), url.scheme?.hasPrefix("http") == true {
                    logger.debug("Text is a URL: \(url.absoluteString)")
                    return SharedInput(
                        kind: .link,
                        url: url,
                        text: nil,
                        suggestedTitle: suggestedTitle ?? url.host
                    )
                }

                logger.debug("Extracted text (\(text.count) chars)")
                return SharedInput(
                    kind: .text,
                    url: nil,
                    text: text,
                    suggestedTitle: suggestedTitle
                )
            }
        } catch {
            logger.warning("Failed to extract text: \(error.localizedDescription)")
        }
        return nil
    }

    private func extractFileData(from provider: NSItemProvider, typeIdentifier: String, suggestedTitle: String?) async -> SharedInput? {
        do {
            let item = try await provider.loadItem(forTypeIdentifier: typeIdentifier)

            if let url = item as? URL {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attributes[.size] as? Int ?? 0
                guard fileSize <= Self.maxFileSizeBytes else {
                    logger.warning("File too large: \(fileSize) bytes, limit: \(Self.maxFileSizeBytes)")
                    return nil
                }
                let data = try Data(contentsOf: url)
                let name = Self.sanitizeFileName(url.lastPathComponent)
                logger.debug("Extracted file: \(name) (\(data.count) bytes)")
                return SharedInput(
                    kind: .file,
                    url: nil,
                    text: nil,
                    suggestedTitle: suggestedTitle,
                    fileData: data,
                    fileName: name
                )
            }

            if let data = item as? Data {
                guard data.count <= Self.maxFileSizeBytes else {
                    logger.warning("Raw data too large: \(data.count) bytes, limit: \(Self.maxFileSizeBytes)")
                    return nil
                }
                let ext = UTType(typeIdentifier)?.preferredFilenameExtension ?? "bin"
                let name = "shared_\(Int(Date().timeIntervalSince1970)).\(ext)"
                logger.debug("Extracted raw data (\(data.count) bytes)")
                return SharedInput(
                    kind: .file,
                    url: nil,
                    text: nil,
                    suggestedTitle: suggestedTitle,
                    fileData: data,
                    fileName: name
                )
            }
        } catch {
            logger.warning("Failed to extract file data: \(error.localizedDescription)")
        }
        return nil
    }

    private static func sanitizeFileName(_ name: String) -> String {
        let cleaned = (name as NSString).lastPathComponent
        let filtered = cleaned.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        let result = String(String.UnicodeScalarView(filtered))
        return result.isEmpty ? "shared_file" : result
    }
}
