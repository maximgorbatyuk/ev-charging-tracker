//
//  PlannedMaintenanceItemView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 05.11.2025.
//

import Foundation
import SwiftUI

struct PlannedMaintenanceItemView: SwiftUICore.View {

    @Environment(\.colorScheme) var colorScheme

    let record: PlannedMaintenanceItem

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.name)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            if record.when != nil || record.odometer != nil {
                PlannedOnView(record: record)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PlannedOnView: SwiftUICore.View {
    let record: PlannedMaintenanceItem

    @State private var now = Date()

    var body: some SwiftUICore.View {
        HStack(spacing: 16) {
            if let when = record.when {
                Label(
                    when.formatted(as: "yyyy-MM-dd"),
                    systemImage: "calendar"
                )
                .font(.subheadline)
                .fontWeight(now > when ? .semibold : .regular)
                .foregroundColor(now > when ? .red : .secondary)
            }

            if let odometer = record.odometer {
                Label(
                    "\(odometer.formatted()) km",
                    systemImage: "speedometer"
                )
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
}
