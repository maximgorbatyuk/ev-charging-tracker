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

    let selectedCar: Car
    let record: PlannedMaintenanceItem
    let onDelete: () -> Void

    var body: some SwiftUICore.View {
        VStack(alignment: .leading) {
            HStack {
                Text(record.name)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            if (record.when != nil || record.odometer != nil) {
                HStack(spacing: 20) {

                    if (record.when != nil) {
                        SmallLabelView(
                            title: L("When"),
                            value: record.when!.formatted(date: .abbreviated, time: .omitted),
                            color: .primary,
                            darkSchemeColor: .white)
                    }

                    if (record.odometer != nil) {
                        SmallLabelView(
                            title: L("Odometer"),
                            value: "\(record.odometer!.formatted()) km",
                            color: .primary,
                            darkSchemeColor: .white)

                        SmallLabelView(
                            title: L("Remain at odometer"),
                            value: "\(record.odometer! - selectedCar.currentMileage) km",
                            color: (record.odometer! - selectedCar.currentMileage) > 0 ? .green : .red,
                            darkSchemeColor: (record.odometer! - selectedCar.currentMileage) > 0 ? .green : .red)
                    }
                }
                .padding(.top, 8)
            }

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .padding(.top, 8)
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
    let color: Color = .primary
    let darkSchemeColor: Color = .white

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 4) {

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? darkSchemeColor : color)
        }
    }
}
