//
//  AppFontAppearance.swift
//  EVChargingTracker
//
//  Applies JetBrains Mono (or system fallback) to UIKit-backed chrome by
//  copying the existing appearance and mutating only the title attributes,
//  preserving whatever background/blur SwiftUI or the system set.
//

import UIKit
import SwiftUI
import Combine

@MainActor
final class AppFontAppearance {
    static let shared = AppFontAppearance()

    private var cancellable: AnyCancellable?

    private init() {}

    func start() {
        apply(language: LocalizationManager.shared.currentLanguage)
        cancellable = LocalizationManager.shared.$currentLanguage
            .sink { [weak self] language in
                self?.apply(language: language)
            }
    }

    private func apply(language: AppLanguage) {
        let navFont = AppFont.resolveUIFont(style: .headline, language: language, weight: .semibold)
        let largeTitleFont = AppFont.resolveUIFont(style: .largeTitle, language: language, weight: .bold)
        let tabFont = AppFont.resolveUIFont(style: .caption2, language: language, weight: .medium)

        applyNavBar(titleFont: navFont, largeTitleFont: largeTitleFont)
        applyTabBar(titleFont: tabFont)
    }

    private func applyNavBar(titleFont: UIFont, largeTitleFont: UIFont) {
        let proxy = UINavigationBar.appearance()

        let standard = proxy.standardAppearance
        var standardTitle = standard.titleTextAttributes
        standardTitle[.font] = titleFont
        standard.titleTextAttributes = standardTitle
        var standardLarge = standard.largeTitleTextAttributes
        standardLarge[.font] = largeTitleFont
        standard.largeTitleTextAttributes = standardLarge

        if let scrollEdge = proxy.scrollEdgeAppearance {
            var title = scrollEdge.titleTextAttributes
            title[.font] = titleFont
            scrollEdge.titleTextAttributes = title
            var large = scrollEdge.largeTitleTextAttributes
            large[.font] = largeTitleFont
            scrollEdge.largeTitleTextAttributes = large
        }

        if let compact = proxy.compactAppearance {
            var title = compact.titleTextAttributes
            title[.font] = titleFont
            compact.titleTextAttributes = title
        }
    }

    private func applyTabBar(titleFont: UIFont) {
        let proxy = UITabBar.appearance()
        updateTabTitle(font: titleFont, in: proxy.standardAppearance)
        if let scrollEdge = proxy.scrollEdgeAppearance {
            updateTabTitle(font: titleFont, in: scrollEdge)
        }
    }

    private func updateTabTitle(font: UIFont, in appearance: UITabBarAppearance) {
        for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            var normal = item.normal.titleTextAttributes
            normal[.font] = font
            item.normal.titleTextAttributes = normal

            var selected = item.selected.titleTextAttributes
            selected[.font] = font
            item.selected.titleTextAttributes = selected

            var disabled = item.disabled.titleTextAttributes
            disabled[.font] = font
            item.disabled.titleTextAttributes = disabled
        }
    }
}
