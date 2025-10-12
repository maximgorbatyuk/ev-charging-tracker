//
//  MainTabView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 12.10.2025.
//

import SwiftUI

struct MainTabView: SwiftUI.View {
    var body: some SwiftUI.View {
        TabView {
            // Your existing charging view
            ContentView()  // Replace with your actual view name
                .tabItem {
                    Label("Car Charging", systemImage: "bolt.car.fill")
                }

            // New settings view
            UserSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "person.circle.fill")
                }
        }
    }
}
