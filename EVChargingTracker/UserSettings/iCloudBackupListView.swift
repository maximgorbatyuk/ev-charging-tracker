//
//  iCloudBackupListView.swift
//  EVChargingTracker
//
//  View for displaying and managing iCloud backups
//

import SwiftUI

struct iCloudBackupListView: View {
    @ObservedObject var viewModel: UserSettingsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var backupToDelete: BackupInfo?
    @State private var showDeleteConfirmation = false
    @State private var backupToRestore: BackupInfo?
    @State private var showRestoreConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoadingBackups {
                    ProgressView(L("Loading backups..."))
                        .progressViewStyle(.circular)
                } else if viewModel.iCloudBackups.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text(L("No backups found"))
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text(L("Create your first backup to get started"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.iCloudBackups) { backup in
                            BackupRow(backup: backup)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    backupToRestore = backup
                                    showRestoreConfirmation = true
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        backupToDelete = backup
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label(L("Delete"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle(L("iCloud Backups"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.loadiCloudBackups()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingBackups)
                }
            }
            .alert(L("Delete Backup?"), isPresented: $showDeleteConfirmation) {
                Button(L("Cancel"), role: .cancel) {
                    backupToDelete = nil
                }
                Button(L("Delete"), role: .destructive) {
                    if let backup = backupToDelete {
                        Task {
                            await viewModel.deleteiCloudBackup(backup)
                            backupToDelete = nil
                        }
                    }
                }
            } message: {
                if let backup = backupToDelete {
                    Text(L("Are you sure you want to delete the backup from \(formatDate(backup.createdAt))?"))
                }
            }
            .alert(L("Restore from Backup?"), isPresented: $showRestoreConfirmation) {
                Button(L("Cancel"), role: .cancel) {
                    backupToRestore = nil
                }
                Button(L("Restore"), role: .destructive) {
                    if let backup = backupToRestore {
                        Task {
                            await viewModel.restoreFromiCloudBackup(backup)
                            backupToRestore = nil
                            dismiss()
                        }
                    }
                }
            } message: {
                if let backup = backupToRestore {
                    Text(L("This will replace all current data with the backup from \(formatDate(backup.createdAt)). This cannot be undone."))
                }
            }
            .alert(L("Backup Error"), isPresented: .constant(viewModel.backupError != nil)) {
                Button(L("OK")) {
                    viewModel.backupError = nil
                }
            } message: {
                if let error = viewModel.backupError {
                    Text(error)
                }
            }
        }
        .task {
            await viewModel.loadiCloudBackups()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BackupRow: View {
    let backup: BackupInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.blue)

                Text(formatDate(backup.createdAt))
                    .font(.headline)

                Spacer()

                Text(backup.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(backup.deviceName)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Label("\(backup.carsCount)", systemImage: "car.fill")
                Label("\(backup.expensesCount)", systemImage: "dollarsign.circle.fill")
                Label("\(backup.maintenanceCount)", systemImage: "wrench.fill")

                Spacer()

                Text("v\(backup.appVersion)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    iCloudBackupListView(viewModel: UserSettingsViewModel())
}
