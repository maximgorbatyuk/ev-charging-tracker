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
    let onDelete: () -> Void

    var body: some SwiftUICore.View {
        VStack(alignment: .leading) {
            HStack {
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 20) {
                
                SmallLabelView(
                    title: L("When"),
                    value: record.when != nil ? "\(record.when!.formatted(date: .abbreviated, time: .omitted))" : "-")

                SmallLabelView(
                    title: L("Odometer"),
                    value: record.odometer != nil ? "\(record.odometer!.formatted()) km" : "-")
            }

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
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

struct SmallLabelView : SwiftUICore.View {
    
    let title: String
    let value: String

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 4) {

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
        }
    }
}
