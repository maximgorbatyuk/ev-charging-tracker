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

  init() {
    self.appVersion = EnvironmentService.shared.getAppVisibleVersion()
    self.developerName = EnvironmentService.shared.getDeveloperName()
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
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)

          /// App version
          Text(appVersion)
            .font(.subheadline)
            .foregroundColor(.secondary)

          /// Developer name
          Text(developerName)
            .font(.caption)
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
