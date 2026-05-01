//
//  LaunchScreenView.swift
//  EVChargingTracker
//
//  Created by Claude on 27.01.2026.
//

import SwiftUI

struct LaunchScreenView: SwiftUI.View {
    private let appVersion: String
    private let developerName: String
    private let fontFamily: AppFontFamily

    init() {
        self.appVersion = EnvironmentService.shared.getAppVisibleVersion()
        self.developerName = EnvironmentService.shared.getDeveloperName()
        // DB-free read so the launch screen never blocks on the database;
        // mirror is kept fresh by AppFontFamilyManager.
        self.fontFamily = AppFontFamilyManager.bootstrapFamily()
    }

    var body: some SwiftUI.View {
        ZStack {
            Color.green.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                /// App icon in rounded square
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)

                VStack(spacing: 8) {
                    /// App name
                    Text(L("EV Charge Tracker"))
                        .appFont(.largeTitle, family: fontFamily, weight: .bold)
                        .foregroundColor(.primary)

                    /// App version
                    Text(appVersion)
                        .appFont(.subheadline, family: fontFamily)
                        .foregroundColor(.secondary)

                    /// Developer name
                    Text(developerName)
                        .appFont(.caption, family: fontFamily)
                        .foregroundColor(.secondary)
                }

                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
