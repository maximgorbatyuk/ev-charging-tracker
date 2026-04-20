//
//  AppFontResolverTests.swift
//  EVChargingTrackerTests
//
//  Verifies language gating and PostScript name selection.
//

import Testing
import SwiftUI
@testable import EVChargingTracker

struct AppFontResolverTests {

    // MARK: - supports(_:)

    @Test func supports_englishGermanRussianTurkishUkrainian_true() {
        #expect(AppFont.supports(.en))
        #expect(AppFont.supports(.de))
        #expect(AppFont.supports(.ru))
        #expect(AppFont.supports(.tr))
        #expect(AppFont.supports(.uk))
    }

    @Test func supports_kazakh_false() {
        #expect(!AppFont.supports(.kk))
    }

    @Test func supports_simplifiedChinese_false() {
        #expect(!AppFont.supports(.zhHans))
    }

    // MARK: - postScriptName(weight:italic:)

    @Test func postScriptName_regularNonItalic_picksRegular() {
        #expect(AppFont.postScriptName(weight: .regular, italic: false) == "JetBrainsMono-Regular")
    }

    @Test func postScriptName_mediumOrSemibold_picksMedium() {
        #expect(AppFont.postScriptName(weight: .medium, italic: false) == "JetBrainsMono-Medium")
        #expect(AppFont.postScriptName(weight: .semibold, italic: false) == "JetBrainsMono-Medium")
    }

    @Test func postScriptName_boldHeavyBlack_picksBold() {
        #expect(AppFont.postScriptName(weight: .bold, italic: false) == "JetBrainsMono-Bold")
        #expect(AppFont.postScriptName(weight: .heavy, italic: false) == "JetBrainsMono-Bold")
        #expect(AppFont.postScriptName(weight: .black, italic: false) == "JetBrainsMono-Bold")
    }

    @Test func postScriptName_italicRegular_picksItalic() {
        #expect(AppFont.postScriptName(weight: .regular, italic: true) == "JetBrainsMono-Italic")
        #expect(AppFont.postScriptName(weight: .medium, italic: true) == "JetBrainsMono-Italic")
    }

    @Test func postScriptName_italicBold_picksBoldItalic() {
        #expect(AppFont.postScriptName(weight: .bold, italic: true) == "JetBrainsMono-BoldItalic")
        #expect(AppFont.postScriptName(weight: .heavy, italic: true) == "JetBrainsMono-BoldItalic")
    }
}
