//
//  UserSettingsTableView.swift
//  EVChargingTracker
//
//  Created by Claude on 21.01.2026.
//

import SwiftUI

/// A debug view that displays all entries from the user_settings table
struct UserSettingsTableView: SwiftUICore.View {

  @Environment(\.dismiss) private var dismiss

  let settings: [UserSettingEntry]

  var body: some SwiftUICore.View {
    NavigationView {
      Group {
        if settings.isEmpty {
          emptyStateView
        } else {
          settingsListView
        }
      }
      .navigationTitle("User Settings Table")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(L("Close")) {
            dismiss()
          }
        }
      }
    }
  }

  private var emptyStateView: some SwiftUICore.View {
    VStack(spacing: 16) {
      Image(systemName: "tablecells")
        .font(.system(size: 64))
        .foregroundColor(.gray.opacity(0.5))

      Text("No settings found")
        .font(.title3)
        .foregroundColor(.gray)
    }
  }

  private var settingsListView: some SwiftUICore.View {
    List {
      Section(header: Text("Table: user_settings (\(settings.count) rows)")) {
        ForEach(settings) { entry in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("ID: \(entry.id)")
                .font(.caption)
                .foregroundColor(.secondary)

              Spacer()
            }

            HStack(alignment: .top) {
              Text(entry.key)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

              Spacer()

              Text(entry.value)
                .font(.subheadline)
                .foregroundColor(.blue)
                .multilineTextAlignment(.trailing)
            }
          }
          .padding(.vertical, 4)
        }
      }
    }
    .listStyle(.insetGrouped)
  }
}

#Preview {
  UserSettingsTableView(settings: [
    UserSettingEntry(id: 1, key: "currency", value: "₸"),
    UserSettingEntry(id: 2, key: "language", value: "en"),
    UserSettingEntry(id: 3, key: "user_id", value: "550e8400-e29b-41d4-a716-446655440000"),
    UserSettingEntry(id: 4, key: "ExpensesDefaultSortingValue", value: "odometer")
  ])
}
