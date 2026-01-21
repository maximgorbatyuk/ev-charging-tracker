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

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.name)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)

            if record.when != nil || record.odometer != nil {
                PlannedOnView(record: record, selectedCar: selectedCar)
            }

            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(3)
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
    let selectedCar: Car

    @State private var now = Date()

    var body: some SwiftUICore.View {
        HStack(spacing: 20) {
            if record.when != nil {
                SmallLabelView(
                    title: L("When"),
                    value: record.when!.formatted(as: "yyyy-MM-dd"),
                    color: now > record.when! ? Color.red : Color.primary,
                    darkSchemeColor: now > record.when! ? Color.red : Color.primary,
                    useBoldFont: now > record.when!)
            }

            if record.odometer != nil {
                SmallLabelView(
                    title: L("Odometer"),
                    value: "\(record.odometer!.formatted()) km",
                    color: Color.primary,
                    darkSchemeColor: Color.white,
                    useBoldFont: false)

                SmallLabelView(
                    title: L("Remain at odometer"),
                    value: "\(record.odometer! - selectedCar.currentMileage) km",
                    color:
                        (record.odometer! - selectedCar.currentMileage) > 0 ? Color.green : Color.red,
                    darkSchemeColor:
                        (record.odometer! - selectedCar.currentMileage) > 0 ? Color.green : Color.red,
                    useBoldFont: (record.odometer! - selectedCar.currentMileage) > 0)
            }
        }
    }
}

struct SmallLabelView : SwiftUICore.View {
    
    let title: String
    let value: String
    let color: Color
    let darkSchemeColor: Color
    let useBoldFont: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 4) {

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? darkSchemeColor : color)
                .fontWeight(useBoldFont ? .semibold : .regular)
        }
    }
}
