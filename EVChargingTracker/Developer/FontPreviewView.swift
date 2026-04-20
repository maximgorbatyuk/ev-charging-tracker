//
//  FontPreviewView.swift
//  EVChargingTracker
//
//  Developer-only QA view. Shows every AppFontStyle rendered under the
//  currently selected language plus the opposite branch (supported vs fallback).
//

import SwiftUI

struct FontPreviewView: SwiftUICore.View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared

    private let styles: [(label: String, style: AppFontStyle, weight: Font.Weight?)] = [
        ("largeTitle", .largeTitle, nil),
        ("title", .title, nil),
        ("title2", .title2, nil),
        ("title3", .title3, nil),
        ("headline", .headline, nil),
        ("subheadline", .subheadline, nil),
        ("body", .body, nil),
        ("body bold", .body, .bold),
        ("body italic", .body, nil),
        ("callout", .callout, nil),
        ("footnote", .footnote, nil),
        ("caption", .caption, nil),
        ("caption2", .caption2, nil),
        ("custom 48pt bold", .custom(size: 48), .bold)
    ]

    private let sampleText = "Charge 4.2 kWh · $0.13 / km"

    var body: some SwiftUICore.View {
        NavigationStack {
            List {
                Section("Current language: \(localization.currentLanguage.rawValue)") {
                    row(for: localization.currentLanguage)
                }

                Section("Supported (en sample)") {
                    row(for: .en)
                }

                Section("Fallback (kk sample)") {
                    row(for: .kk)
                }

                Section("Fallback (zh-Hans sample)") {
                    row(for: .zhHans)
                }
            }
            .navigationTitle("Font preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(for language: AppLanguage) -> some SwiftUICore.View {
        ForEach(styles.indices, id: \.self) { idx in
            let entry = styles[idx]
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(sampleText)
                    .font(font(for: entry, language: language, italic: entry.label.contains("italic")))
            }
        }
    }

    private func font(
        for entry: (label: String, style: AppFontStyle, weight: Font.Weight?),
        language: AppLanguage,
        italic: Bool
    ) -> Font {
        AppFont.resolve(
            style: entry.style,
            language: language,
            weight: entry.weight,
            italic: italic
        )
    }
}
