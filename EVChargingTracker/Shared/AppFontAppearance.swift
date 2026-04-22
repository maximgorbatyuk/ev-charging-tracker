//
//  AppFontAppearance.swift
//  EVChargingTracker
//
//  Applies JetBrains Mono (or system fallback) to UIKit-backed chrome.
//  Ensures every appearance slot (standard, scrollEdge, compact) has our
//  font — iOS caches scroll-edge state from the proxy at first render, so
//  nil scrollEdge/compact slots would silently drop the font.
//

import UIKit
import SwiftUI
import Combine

@MainActor
final class AppFontAppearance {
    static let shared = AppFontAppearance()

    private var cancellables = Set<AnyCancellable>()

    private init() {}

    func start() {
        applyCurrent()

        LocalizationManager.shared.$currentLanguage
            .sink { [weak self] _ in self?.applyCurrent() }
            .store(in: &cancellables)

        AppFontFamilyManager.shared.$currentFamily
            .sink { [weak self] _ in self?.applyCurrent() }
            .store(in: &cancellables)
    }

    private func applyCurrent() {
        apply(
            language: LocalizationManager.shared.currentLanguage,
            family: AppFontFamilyManager.shared.currentFamily
        )
    }

    private func apply(language: AppLanguage, family: AppFontFamily) {
        let navFont = AppFont.resolveUIFont(style: .headline, language: language, family: family, weight: .semibold)
        let largeTitleFont = AppFont.resolveUIFont(style: .largeTitle, language: language, family: family, weight: .bold)
        let tabFont = AppFont.resolveUIFont(style: .caption2, language: language, family: family, weight: .medium)

        applyNavBar(titleFont: navFont, largeTitleFont: largeTitleFont)
        applyTabBar(titleFont: tabFont)
    }

    private func applyNavBar(titleFont: UIFont, largeTitleFont: UIFont) {
        let proxy = UINavigationBar.appearance()

        let standard = proxy.standardAppearance
        injectTitle(titleFont, largeTitle: largeTitleFont, into: standard)
        proxy.standardAppearance = standard

        let scrollEdge = proxy.scrollEdgeAppearance ?? {
            let a = UINavigationBarAppearance()
            a.configureWithTransparentBackground()
            return a
        }()
        injectTitle(titleFont, largeTitle: largeTitleFont, into: scrollEdge)
        proxy.scrollEdgeAppearance = scrollEdge

        let compact = proxy.compactAppearance ?? UINavigationBarAppearance()
        injectTitle(titleFont, largeTitle: largeTitleFont, into: compact)
        proxy.compactAppearance = compact
    }

    private func injectTitle(
        _ titleFont: UIFont,
        largeTitle: UIFont,
        into appearance: UINavigationBarAppearance
    ) {
        var title = appearance.titleTextAttributes
        title[.font] = titleFont
        appearance.titleTextAttributes = title

        var large = appearance.largeTitleTextAttributes
        large[.font] = largeTitle
        appearance.largeTitleTextAttributes = large
    }

    private func applyTabBar(titleFont: UIFont) {
        let proxy = UITabBar.appearance()

        let standard = proxy.standardAppearance
        updateTabTitle(font: titleFont, in: standard)
        proxy.standardAppearance = standard

        let scrollEdge = proxy.scrollEdgeAppearance ?? UITabBarAppearance()
        updateTabTitle(font: titleFont, in: scrollEdge)
        proxy.scrollEdgeAppearance = scrollEdge
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
