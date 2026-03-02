//
//  CarQuickAddSheet.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.03.2026.
//

import SwiftUI

enum CarQuickAddOption: String, CaseIterable, Identifiable {
    case maintenance
    case document
    case idea

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .maintenance: return L("New maintenance record")
        case .document: return L("New document")
        case .idea: return L("New idea")
        }
    }

    var iconName: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .document: return "doc.fill"
        case .idea: return "lightbulb.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .maintenance: return .blue
        case .document: return .orange
        case .idea: return .yellow
        }
    }

    var route: CarFlowRoute {
        switch self {
        case .maintenance: return .maintenance
        case .document: return .documents
        case .idea: return .ideas
        }
    }
}

struct CarQuickAddSheet: SwiftUI.View {

    let onOptionSelected: (CarQuickAddOption) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some SwiftUI.View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(CarQuickAddOption.allCases) { option in
                        CarQuickAddOptionButton(option: option) {
                            dismiss()
                            onOptionSelected(option)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(L("Create new"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CarQuickAddOptionButton: SwiftUI.View {

    let option: CarQuickAddOption
    let action: () -> Void

    var body: some SwiftUI.View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(option.iconColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: option.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(option.iconColor)
                }

                Text(option.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CarQuickAddSheet(onOptionSelected: { _ in })
}
