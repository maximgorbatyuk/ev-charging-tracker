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

        // `@Published` emits on `willSet`, so the wrappedValue we'd re-read
        // from the source inside the sink is still the OLD value. Use the
        // value the publisher hands us instead — that's the new one being
        // assigned. Without this, UIKit appearance lags one tap behind
        // SwiftUI re-renders, producing the body/title font swap.
        LocalizationManager.shared.$currentLanguage
            .sink { [weak self] newLanguage in
                self?.apply(
                    language: newLanguage,
                    family: AppFontFamilyManager.shared.currentFamily
                )
            }
            .store(in: &cancellables)

        AppFontFamilyManager.shared.$currentFamily
            .sink { [weak self] newFamily in
                self?.apply(
                    language: LocalizationManager.shared.currentLanguage,
                    family: newFamily
                )
            }
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
        refreshLiveBars()
    }

    /// `UI{NavigationBar,TabBar}.appearance()` only affects bars created
    /// AFTER the proxy is mutated — currently-visible bars keep their cached
    /// appearance until they're re-instantiated. Walk live windows and copy
    /// the proxy values onto the visible bars so font changes show up
    /// immediately, not only after navigation.
    private func refreshLiveBars() {
        let navProxy = UINavigationBar.appearance()
        let standardNav = navProxy.standardAppearance
        let scrollEdgeNav = navProxy.scrollEdgeAppearance
        let compactNav = navProxy.compactAppearance

        let tabProxy = UITabBar.appearance()
        let standardTab = tabProxy.standardAppearance
        let scrollEdgeTab = tabProxy.scrollEdgeAppearance

        for scene in UIApplication.shared.connectedScenes {
            guard
                let windowScene = scene as? UIWindowScene,
                windowScene.activationState != .unattached
            else { continue }
            for window in windowScene.windows {
                guard let root = window.rootViewController else { continue }
                walk(root) { vc in
                    if let nav = vc as? UINavigationController {
                        nav.navigationBar.standardAppearance = standardNav
                        nav.navigationBar.scrollEdgeAppearance = scrollEdgeNav
                        nav.navigationBar.compactAppearance = compactNav
                        nav.navigationBar.setNeedsLayout()
                    }
                    if let tab = vc as? UITabBarController {
                        tab.tabBar.standardAppearance = standardTab
                        tab.tabBar.scrollEdgeAppearance = scrollEdgeTab
                        tab.tabBar.setNeedsLayout()
                    }
                }
            }
        }
    }

    private func walk(_ vc: UIViewController, visit: (UIViewController) -> Void) {
        visit(vc)
        for child in vc.children {
            walk(child, visit: visit)
        }
        if let presented = vc.presentedViewController {
            walk(presented, visit: visit)
        }
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
