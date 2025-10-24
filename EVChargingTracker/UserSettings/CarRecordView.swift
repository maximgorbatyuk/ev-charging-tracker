//
//  CarRecordViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 24.10.2025.
//

import SwiftUI

struct CarRecordView: SwiftUICore.View  {
    
    @Environment(\.colorScheme) var colorScheme

    let car: CarDto
    let onDelete: () -> Void

    var body: some SwiftUICore.View {
        // compute common values up front to simplify chained expressions
        let textColor: Color = (colorScheme == .dark) ? .white : Color.black.opacity(0.9)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(car.name)
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.gray.opacity(0.7))
                }
                .disabled(true)
            }
            
            HStack(spacing: 20) {
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Initial millage")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(car.initialMileage.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Current millage")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text("\(car.currentMileage.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(textColor)
                }

                // Safely unwrap optional batteryCapacity to avoid complex optional chaining inside interpolations
                if let battery = car.batteryCapacity {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Battery")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("\(battery.formatted()) kWh")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(textColor)
                    }
                }
            }

            Text(car.selectedForTracking ? "Tracking" : "Not tracking")
                .fontWeight(.semibold)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(car.selectedForTracking ? .green : .red)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
