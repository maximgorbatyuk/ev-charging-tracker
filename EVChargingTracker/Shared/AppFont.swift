//
//  AppFont.swift
//  EVChargingTracker
//
//  Language-aware font resolver. Supported languages render in JetBrains Mono;
//  Kazakh and Simplified Chinese fall back to the system font because JetBrains
//  Mono does not ship glyphs for their scripts.
//

import SwiftUI
import UIKit

enum AppFontStyle {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case subheadline
    case body
    case callout
    case footnote
    case caption
    case caption2
    case custom(size: CGFloat, relativeTo: Font.TextStyle = .body)
}

enum AppFont {
    /// Does JetBrains Mono cover this language's script? Kazakh Cyrillic
    /// extensions and CJK are excluded. `.system` family ignores this.
    static func supports(_ language: AppLanguage) -> Bool {
        switch language {
        case .kk, .zhHans:
            return false
        default:
            return true
        }
    }

    /// Whether the custom (JetBrains Mono) path should be taken. False when
    /// the user picked `.system`, or when the language isn't covered.
    private static func shouldUseCustom(
        family: AppFontFamily,
        language: AppLanguage
    ) -> Bool {
        family == .jetBrainsMono && supports(language)
    }

    static func resolve(
        style: AppFontStyle,
        language: AppLanguage,
        family: AppFontFamily = AppFontFamilyManager.shared.currentFamily,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> Font {
        let (size, textStyle, defaultWeight) = metrics(for: style)
        let effectiveWeight = weight ?? defaultWeight

        guard shouldUseCustom(family: family, language: language) else {
            let base = systemFont(style: style, weight: effectiveWeight)
            return italic ? base.italic() : base
        }

        let postScript = postScriptName(weight: effectiveWeight, italic: italic)
        return Font.custom(postScript, size: size, relativeTo: textStyle)
    }

    static func resolveUIFont(
        style: AppFontStyle,
        language: AppLanguage,
        family: AppFontFamily = AppFontFamilyManager.shared.currentFamily,
        weight: Font.Weight = .regular,
        italic: Bool = false
    ) -> UIFont {
        let (size, textStyle, _) = metrics(for: style)
        let scaler = UIFontMetrics(forTextStyle: uiKitTextStyle(from: textStyle))

        if shouldUseCustom(family: family, language: language),
           let custom = UIFont(
               name: postScriptName(weight: weight, italic: italic),
               size: size
           ) {
            return scaler.scaledFont(for: custom)
        }

        let system = UIFont.systemFont(ofSize: size, weight: uiKitWeight(from: weight))
        return scaler.scaledFont(for: system)
    }

    private static let regularName = "JetBrainsMono-Regular"
    private static let mediumName = "JetBrainsMono-Medium"
    private static let boldName = "JetBrainsMono-Bold"
    private static let italicName = "JetBrainsMono-Italic"
    private static let boldItalicName = "JetBrainsMono-BoldItalic"

    private static func systemFont(style: AppFontStyle, weight: Font.Weight) -> Font {
        switch style {
        case .largeTitle: return .system(.largeTitle, design: .default).weight(weight)
        case .title: return .system(.title, design: .default).weight(weight)
        case .title2: return .system(.title2, design: .default).weight(weight)
        case .title3: return .system(.title3, design: .default).weight(weight)
        case .headline: return .system(.headline, design: .default).weight(weight)
        case .subheadline: return .system(.subheadline, design: .default).weight(weight)
        case .body: return .system(.body, design: .default).weight(weight)
        case .callout: return .system(.callout, design: .default).weight(weight)
        case .footnote: return .system(.footnote, design: .default).weight(weight)
        case .caption: return .system(.caption, design: .default).weight(weight)
        case .caption2: return .system(.caption2, design: .default).weight(weight)
        case let .custom(size, _):
            return .system(size: size, weight: weight)
        }
    }

    private static func metrics(
        for style: AppFontStyle
    ) -> (size: CGFloat, textStyle: Font.TextStyle, defaultWeight: Font.Weight) {
        switch style {
        case .largeTitle: return (34, .largeTitle, .regular)
        case .title: return (28, .title, .regular)
        case .title2: return (22, .title2, .regular)
        case .title3: return (20, .title3, .regular)
        case .headline: return (17, .headline, .semibold)
        case .subheadline: return (15, .subheadline, .regular)
        case .body: return (17, .body, .regular)
        case .callout: return (16, .callout, .regular)
        case .footnote: return (13, .footnote, .regular)
        case .caption: return (12, .caption, .regular)
        case .caption2: return (11, .caption2, .regular)
        case let .custom(size, relativeTo):
            return (size, relativeTo, .regular)
        }
    }

    static func postScriptName(weight: Font.Weight, italic: Bool) -> String {
        let isBold = weight == .bold || weight == .heavy || weight == .black
        let isMedium = weight == .medium || weight == .semibold
        switch (isBold, italic) {
        case (true, true): return boldItalicName
        case (true, false): return boldName
        case (false, true): return italicName
        case (false, false): return isMedium ? mediumName : regularName
        }
    }

    private static func uiKitWeight(from weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }

    private static func uiKitTextStyle(from style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

private struct AppFontModifier: ViewModifier {
    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var fontFamily = AppFontFamilyManager.shared
    let style: AppFontStyle
    let weight: Font.Weight?
    let italic: Bool

    func body(content: Content) -> some SwiftUI.View {
        content.font(
            AppFont.resolve(
                style: style,
                language: localization.currentLanguage,
                family: fontFamily.currentFamily,
                weight: weight,
                italic: italic
            )
        )
    }
}

extension SwiftUI.View {
    func appFont(
        _ style: AppFontStyle,
        weight: Font.Weight? = nil,
        italic: Bool = false
    ) -> some SwiftUI.View {
        modifier(AppFontModifier(style: style, weight: weight, italic: italic))
    }
}
