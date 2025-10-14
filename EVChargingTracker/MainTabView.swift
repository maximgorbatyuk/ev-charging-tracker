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
            ChargingSessionsView()
                .tabItem {
                    Label("Stats", systemImage: "bolt.car.fill")
                }
            
            ExpensesView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.circle")
                }

            UserSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "person.circle.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
}
