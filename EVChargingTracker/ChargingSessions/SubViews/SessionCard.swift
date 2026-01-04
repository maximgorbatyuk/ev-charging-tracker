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
    let onEdit: () -> Void
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 8)
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }

            HStack(spacing: 20) {
                
                if (session.expenseType == .charging) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("Energy"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: L("%.1f kWh"), session.energyCharged))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("Expense type"))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(L(session.expenseType.rawValue))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Odometer"))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(session.odometer.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                if let cost = session.cost {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("Cost"))
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
