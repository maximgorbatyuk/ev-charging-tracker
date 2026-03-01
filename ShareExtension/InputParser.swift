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

    /// Parses NSExtensionItem attachments into a SharedInput.
    /// Priority: URL → plain text.
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
}
