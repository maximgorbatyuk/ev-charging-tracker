//
//  FilterChip.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 31.01.2026.
//

import SwiftUI
import UIKit

struct FilterChip: SwiftUICore.View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some SwiftUICore.View {
    Button(action: action) {
      Text(title)
        .font(.subheadline)
        .fontWeight(isSelected ? .semibold : .regular)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.orange : Color(UIColor.systemGray5))
        .foregroundColor(isSelected ? .white : .primary)
        .cornerRadius(20)
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  HStack {
    FilterChip(title: "All", isSelected: true) {}
    FilterChip(title: "Charging", isSelected: false) {}
    FilterChip(title: "Maintenance", isSelected: false) {}
  }
  .padding()
}
