//
//  NoExpensesView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 17.10.2025.
//

import SwiftUI

struct NoExpensesView: SwiftUICore.View {
    var body: some SwiftUICore.View {
        VStack(spacing: 16) {
            Image(systemName: "battery.100.bolt")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(NSLocalizedString("No charging sessions yet", comment: "Empty state title when there are no charging sessions"))
                .font(.title3)
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("Add your first session to start tracking", comment: "Empty state subtitle prompting to add first session"))
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.9))
        }
    }
}
