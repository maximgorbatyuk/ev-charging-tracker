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
                
                if (session.expenseType == .charging) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.headline)

                        Text(String(format: L("%.1f kWh"), session.energyCharged))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                } else {
                    HStack {

                        if (session.expenseType == .maintenance || session.expenseType == .repair) {
                            Image(systemName: "wrench.fill")
                                .foregroundColor(.blue)
                                .font(.headline)
                        } else if (session.expenseType == .carwash) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.cyan)
                                .font(.headline)
                        } else {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.green)
                                .font(.headline)
                        }

                        Text(L(session.expenseType.rawValue))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }

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

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Date"))
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(session.date.formatted(as: "yyyy-MM-dd"))
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("Odometer"))
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(session.odometer.formatted()) km")
                        .font(.subheadline)
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
