//
//  NoExpensesView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 17.10.2025.
//

import SwiftUI

struct NoExpensesView: SwiftUICore.View {

    var body: some SwiftUICore.View {
        VStack(spacing: 20) {
            Image(systemName: "battery.100.bolt")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text(L("No charging sessions yet"))
                .font(.title3)
                .foregroundColor(.gray)
            
            Text(L("Add your first session to start tracking"))
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.9))
        }
    }
}
