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
    let onDelete: () -> Void
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            if (session.expenseType == .charging) {
                Text(NSLocalizedString(session.chargerType.rawValue, comment: "Charger type human readable"))
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            } else {
                // TODO mgorbatyuk: write notes if available
            }

            HStack(spacing: 20) {
                
                if (session.expenseType == .charging) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Energy", comment: "Label for energy charged"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: NSLocalizedString("%.1f kWh", comment: "Energy value with unit"), session.energyCharged))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Expense type", comment: "Label for expense type"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(NSLocalizedString(session.expenseType.rawValue, comment: "Expense type human readable"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("Odometer", comment: "Label for odometer"))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(session.odometer.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.9))
                }
                
                if let cost = session.cost {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("Cost", comment: "Label for cost"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%@%.2f", session.currency.rawValue, cost))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            
            if (session.expenseType == .charging && session.notes != "") {
                Text(session.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
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
