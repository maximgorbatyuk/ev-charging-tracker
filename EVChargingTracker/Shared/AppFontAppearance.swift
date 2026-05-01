//
//  AppFontAppearance.swift
//  EVChargingTracker
//
//  Applies JetBrains Mono (or system fallback) to UIKit-backed chrome.
//  The `UIAppearance` proxy does not reliably propagate `scrollEdgeAppearance`
//  to `UINavigationBar` instances created by SwiftUI's `NavigationView` /
//  `NavigationStack`, so we additionally walk live windows and force-write
//  the appearance onto each `nav.navigationBar` AND every VC's
//  `navigationItem` (which shadows the bar-level slot in SwiftUI). The walk
//  re-runs on scene activation and on font/language change.
//

import UIKit
import SwiftUI
import Combine

@MainActor
final class AppFontAppearance {
    static let shared = AppFontAppearance()

    private var cancellables = Set<AnyCancellable>()

    // Cached copies of the appearances we install. The `UIAppearance` proxy
    // (`UINavigationBar.appearance()` / `UITabBar.appearance()`) stores
    // assigned values for application to NEW instances but is unreliable
    // when read back — particularly for `scrollEdgeAppearance`, which was
    // bolted onto `UIAppearance` after the original API. Reading the proxy
    // can return a font-less default even after we've stored a customized
    // appearance, which would propagate the wrong values in `refreshLiveBars`.
    // Owning our own cache makes the pipeline deterministic.
    private var navStandardAppearance: UINavigationBarAppearance?
    private var navScrollEdgeAppearance: UINavigationBarAppearance?
    private var navCompactAppearance: UINavigationBarAppearance?
    private var tabStandardAppearance: UITabBarAppearance?
    private var tabScrollEdgeAppearance: UITabBarAppearance?

    private init() {}

    func start() {
        // Idempotency guard: if a scene-reconnection or double-init ever
        // calls `start()` again, don't register the sinks twice.
        guard cancellables.isEmpty else { return }

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

        // `start()` runs in App.init() — before any SwiftUI scene/window
        // exists — so the first `refreshLiveBars()` is a no-op. Re-run on
        // every scene activation so back-from-background and multi-scene
        // (iPad) cases also get patched. The runloop hop ensures SwiftUI
        // has a chance to mount any newly-attached nav controllers first.
        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshLiveBars()
                }
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

    /// Force-write our cached appearance onto every live `UINavigationBar`
    /// and `UITabBar` in foreground-active windows, including the
    /// per-VC `navigationItem.{slot}Appearance` slots, which SwiftUI may
    /// install with empty font attrs and which would otherwise shadow the
    /// bar-level write. Reads our cached appearance objects rather than
    /// the `UIAppearance` proxy because proxy reads (especially of
    /// `scrollEdgeAppearance`) can return a font-less default even after
    /// we've assigned a customized value — propagating that to live bars
    /// is what produced the "system font in scroll-edge state, mono in
    /// standard state" symptom.
    ///
    /// Per-VC overwrite is unconditional. This clobbers any `.toolbarBackground`
    /// or per-screen appearance customization. None exist in this codebase
    /// today; if one is added, this method must move to merge-style.
    func refreshLiveBars() {
        guard
            let standardNav = navStandardAppearance,
            let scrollEdgeNav = navScrollEdgeAppearance,
            let compactNav = navCompactAppearance,
            let standardTab = tabStandardAppearance,
            let scrollEdgeTab = tabScrollEdgeAppearance
        else { return }

        for scene in UIApplication.shared.connectedScenes {
            guard
                let windowScene = scene as? UIWindowScene,
                windowScene.activationState == .foregroundActive
            else { continue }
            for window in windowScene.windows {
                guard let root = window.rootViewController else { continue }
                walk(root) { vc in
                    if let nav = vc as? UINavigationController {
                        nav.navigationBar.standardAppearance = standardNav
                        nav.navigationBar.scrollEdgeAppearance = scrollEdgeNav
                        nav.navigationBar.compactAppearance = compactNav
                        nav.navigationBar.setNeedsLayout()

                        for childVC in nav.viewControllers {
                            let item = childVC.navigationItem
                            item.standardAppearance = standardNav
                            item.scrollEdgeAppearance = scrollEdgeNav
                            item.compactAppearance = compactNav
                        }
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

        // `.copy()` so we own an independent appearance object — avoids
        // accidental shared-reference mutations leaking back into the
        // proxy, and lets us safely cache it for `refreshLiveBars`.
        let standard = (proxy.standardAppearance.copy() as? UINavigationBarAppearance) ?? UINavigationBarAppearance()
        injectTitle(titleFont, largeTitle: largeTitleFont, into: standard)
        proxy.standardAppearance = standard
        navStandardAppearance = standard

        let scrollEdge: UINavigationBarAppearance = {
            if let copy = proxy.scrollEdgeAppearance?.copy() as? UINavigationBarAppearance {
                return copy
            }
            let a = UINavigationBarAppearance()
            a.configureWithTransparentBackground()
            return a
        }()
        injectTitle(titleFont, largeTitle: largeTitleFont, into: scrollEdge)
        proxy.scrollEdgeAppearance = scrollEdge
        navScrollEdgeAppearance = scrollEdge

        let compact = (proxy.compactAppearance?.copy() as? UINavigationBarAppearance) ?? UINavigationBarAppearance()
        injectTitle(titleFont, largeTitle: largeTitleFont, into: compact)
        proxy.compactAppearance = compact
        navCompactAppearance = compact
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

        let standard = (proxy.standardAppearance.copy() as? UITabBarAppearance) ?? UITabBarAppearance()
        updateTabTitle(font: titleFont, in: standard)
        proxy.standardAppearance = standard
        tabStandardAppearance = standard

        let scrollEdge = (proxy.scrollEdgeAppearance?.copy() as? UITabBarAppearance) ?? UITabBarAppearance()
        updateTabTitle(font: titleFont, in: scrollEdge)
        proxy.scrollEdgeAppearance = scrollEdge
        tabScrollEdgeAppearance = scrollEdge
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
