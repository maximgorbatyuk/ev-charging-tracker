//
//  CarRecordViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 24.10.2025.
//

import SwiftUI

struct CarRecordView: SwiftUICore.View  {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var loc = LocalizationManager.shared

    let car: CarDto

    var body: some SwiftUICore.View {
        // compute common values up front to simplify chained expressions
        let textColor: Color = (colorScheme == .dark) ? .white : Color.primary

        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(car.name)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()

                Image(systemName: "pencil")
                    .foregroundColor(.gray.opacity(0.7))
            }
            
            HStack(spacing: 20) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Initial millage"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(car.initialMileage.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Current millage"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(car.currentMileage.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Currency"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(car.expenseCurrency.shortName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }
            }

            Text(car.selectedForTracking ? L("Tracking") : L("Not tracking"))
                .fontWeight(.semibold)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(car.selectedForTracking ? .green : .red)
        }
    }
}
