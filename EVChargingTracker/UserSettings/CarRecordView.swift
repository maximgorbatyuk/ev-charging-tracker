//
//  CarRecordViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 24.10.2025.
//

import SwiftUI

struct CarRecordView: SwiftUICore.View {

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var loc = LocalizationManager.shared

    let car: CarDto

    var body: some SwiftUICore.View {
        // compute common values up front to simplify chained expressions
        let textColor: Color = (colorScheme == .dark) ? .white : Color.primary

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(car.name)
                    .appFont(.headline)
                    .foregroundColor(.gray)
                Spacer()

                Image(systemName: "pencil")
                    .foregroundColor(.gray.opacity(0.7))
            }

            HStack(spacing: 20) {

                let unit = car.measurementSystem.distanceUnitLabel

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Current mileage"))
                        .appFont(.caption)
                        .foregroundColor(.gray)

                    Text("\(car.currentMileage.formatted()) \(unit)")
                        .appFont(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Rides"))
                        .appFont(.caption)
                        .foregroundColor(.gray)

                    Text("\((car.currentMileage - car.initialMileage).formatted()) \(unit)")
                        .appFont(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Currency"))
                        .appFont(.caption)
                        .foregroundColor(.gray)

                    Text(car.expenseCurrency.shortName)
                        .appFont(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }
            }

            Text(car.selectedForTracking ? L("Tracking") : L("Not tracking"))
                .fontWeight(.semibold)
                .appFont(.custom(size: 16), weight: .regular)
                .foregroundColor(car.selectedForTracking ? .green : .red)
        }
    }
}
