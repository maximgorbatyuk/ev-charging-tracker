//
//  PlannedMaintenanceDetailsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 31.01.2026.
//

import SwiftUI

struct PlannedMaintenanceDetailsView: SwiftUICore.View {

  let record: PlannedMaintenanceItem
  let selectedCar: Car
  let onMarkAsDone: (PlannedMaintenanceItem) -> Void
  let onEdit: (PlannedMaintenanceItem) -> Void
  let onDelete: (PlannedMaintenanceItem) -> Void
  let onDuplicate: (PlannedMaintenanceItem) -> Void

  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) var colorScheme
  @ObservedObject private var analytics = AnalyticsService.shared

  @State private var showingDeleteConfirmation = false

  var body: some SwiftUICore.View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          detailsSection
          actionsSection
        }
        .padding()
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(L("Maintenance Details"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(L("Close")) {
            dismiss()
          }
        }
      }
      .alert(L("Delete maintenance record?"), isPresented: $showingDeleteConfirmation) {
        Button(L("Cancel"), role: .cancel) {}
        Button(L("Delete"), role: .destructive) {
          analytics.trackEvent("maintenance_deleted_from_details", properties: [
            "screen": "maintenance_details_screen"
          ])
          onDelete(record)
          dismiss()
        }
      } message: {
        Text(L("Delete selected maintenance record? This action cannot be undone."))
      }
      .onAppear {
        analytics.trackScreen("maintenance_details_screen")
      }
    }
  }

  private var detailsSection: some SwiftUICore.View {
    VStack(alignment: .leading, spacing: 16) {
      /// Title
      VStack(alignment: .leading, spacing: 4) {
        Text(L("Title"))
          .font(.caption)
          .foregroundColor(.gray)
        Text(record.name)
          .font(.title2)
          .fontWeight(.semibold)
      }

      Divider()

      /// Scheduled date
      if let when = record.when {
        detailRow(
          title: L("Scheduled Date"),
          value: when.formatted(as: "yyyy-MM-dd"),
          status: statusForDate(when)
        )
        Divider()
      }

      /// Target odometer
      if let odometer = record.odometer {
        detailRow(
          title: L("Target Odometer"),
          value: "\(odometer.formatted()) km",
          status: nil
        )

        let remaining = odometer - selectedCar.currentMileage
        detailRow(
          title: L("Remaining Distance"),
          value: "\(remaining.formatted()) km",
          status: remaining > 0 ? .normal : .overdue
        )
        Divider()
      }

      /// Notes
      if !record.notes.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text(L("Notes"))
            .font(.caption)
            .foregroundColor(.gray)
          Text(record.notes)
            .font(.body)
        }
        Divider()
      }

      /// Created at
      VStack(alignment: .leading, spacing: 4) {
        Text(L("Created"))
          .font(.caption)
          .foregroundColor(.gray)
        Text(record.createdAt.formatted(as: "yyyy-MM-dd"))
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
    )
  }

  private var actionsSection: some SwiftUICore.View {
    HStack(spacing: 16) {
      actionButton(
        icon: "checkmark.circle",
        title: L("Done"),
        color: .green
      ) {
        analytics.trackEvent("mark_as_done_from_details", properties: [
          "screen": "maintenance_details_screen"
        ])
        onMarkAsDone(record)
        dismiss()
      }

      actionButton(
        icon: "pencil",
        title: L("Edit"),
        color: .orange
      ) {
        analytics.trackEvent("edit_from_details", properties: [
          "screen": "maintenance_details_screen"
        ])
        onEdit(record)
        dismiss()
      }

      actionButton(
        icon: "doc.on.doc",
        title: L("Duplicate"),
        color: .blue
      ) {
        analytics.trackEvent("duplicate_from_details", properties: [
          "screen": "maintenance_details_screen"
        ])
        onDuplicate(record)
        dismiss()
      }

      actionButton(
        icon: "trash",
        title: L("Delete"),
        color: .red
      ) {
        showingDeleteConfirmation = true
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
    )
  }

  private func actionButton(
    icon: String,
    title: String,
    color: Color,
    action: @escaping () -> Void
  ) -> some SwiftUICore.View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: icon)
          .font(.title2)
        Text(title)
          .font(.caption)
      }
      .frame(maxWidth: .infinity)
      .foregroundColor(color)
    }
    .buttonStyle(.plain)
  }

  private func detailRow(title: String, value: String, status: RecordStatus?) -> some SwiftUICore.View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.caption)
          .foregroundColor(.gray)
        Text(value)
          .font(.body)
          .fontWeight(status == .overdue ? .semibold : .regular)
          .foregroundColor(colorForStatus(status))
      }
      Spacer()
      if let status = status {
        statusBadge(for: status)
      }
    }
  }

  private func statusForDate(_ date: Date) -> RecordStatus {
    let now = Date()
    if date < now {
      return .overdue
    }

    let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: date).day ?? 0
    if daysRemaining <= 7 {
      return .dueSoon
    }

    return .normal
  }

  private func colorForStatus(_ status: RecordStatus?) -> Color {
    switch status {
    case .overdue:
      return .red
    case .dueSoon:
      return .orange
    case .normal, .none:
      return .primary
    }
  }

  private func statusBadge(for status: RecordStatus) -> some SwiftUICore.View {
    Text(status.displayName)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(colorForStatus(status).opacity(0.2))
      .foregroundColor(colorForStatus(status))
      .cornerRadius(8)
  }
}

enum RecordStatus {
  case overdue
  case dueSoon
  case normal

  var displayName: String {
    switch self {
    case .overdue:
      return L("Overdue")
    case .dueSoon:
      return L("Due Soon")
    case .normal:
      return L("Scheduled")
    }
  }
}
