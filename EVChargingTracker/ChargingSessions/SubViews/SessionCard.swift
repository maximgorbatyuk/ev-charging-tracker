//
//  SessionCard.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 11.10.2025.
//
import Foundation
import SwiftUI

struct SessionCard: SwiftUICore.View {

    @Environment(\.colorScheme) var colorScheme

    let session: Expense

    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if session.expenseType == .charging {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                        .appFont(.headline)

                    Text(String(format: L("%.1f kWh"), session.energyCharged))
                        .appFont(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                } else {
                    expenseTypeIcon

                    Text(L(session.expenseType.rawValue))
                        .appFont(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }

                Spacer()

                if let cost = session.cost {
                    Text(String(format: "%@%.2f", session.currency.rawValue, cost))
                        .appFont(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }

            HStack(spacing: 16) {
                Label(
                    session.date.formatted(as: "yyyy-MM-dd"),
                    systemImage: "calendar"
                )
                .appFont(.subheadline)
                .foregroundColor(.secondary)

                Label(
                    "\(session.odometer.formatted()) km",
                    systemImage: "speedometer"
                )
                .appFont(.subheadline)
                .foregroundColor(.secondary)

                Spacer()
            }

            if !session.notes.isEmpty {
                Text(session.notes)
                    .appFont(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
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

    @ViewBuilder
    private var expenseTypeIcon: some SwiftUICore.View {
        switch session.expenseType {
        case .maintenance, .repair:
            Image(systemName: "wrench.fill")
                .foregroundColor(.blue)
                .appFont(.headline)

        case .carwash:
            Image(systemName: "drop.fill")
                .foregroundColor(.cyan)
                .appFont(.headline)

        default:
            Image(systemName: "creditcard.fill")
                .foregroundColor(.green)
                .appFont(.headline)
        }
    }
}
