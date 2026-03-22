//
//  AppLanguageTests.swift
//  EVChargingTrackerTests
//
//  Tests for AppLanguage enum and localization persistence
//

import Testing
@testable import EVChargingTracker

struct AppLanguageTests {

    // MARK: - Raw value resolution

    @Test func zhHans_rawValue_resolvesCorrectly() {
        let language = AppLanguage(rawValue: "zh-Hans")
        #expect(language == .zhHans)
    }

    @Test func zhHans_displayName_isSimplifiedChinese() {
        #expect(AppLanguage.zhHans.displayName == "🇨🇳 简体中文")
    }

    @Test func allCases_containsZhHans() {
        #expect(AppLanguage.allCases.contains(.zhHans))
    }

    @Test func allLanguages_haveUniqueRawValues() {
        let rawValues = AppLanguage.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    // MARK: - Persistence via MockUserSettingsRepository

    @Test func zhHans_canBePersisted_throughRepository() {
        let repository = MockUserSettingsRepository()

        let upserted = repository.upsertLanguage("zh-Hans")
        #expect(upserted == true)

        let fetched = repository.fetchLanguage()
        #expect(fetched == .zhHans)
    }

    @Test func zhHans_roundTrips_throughCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(AppLanguage.zhHans)
        let decoded = try decoder.decode(AppLanguage.self, from: data)

        #expect(decoded == .zhHans)
    }
}
