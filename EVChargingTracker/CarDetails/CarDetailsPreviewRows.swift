//
//  CarDetailsPreviewRows.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 02.03.2026.
//

import SwiftUI

struct MaintenancePreviewRow: SwiftUI.View {

    let record: PlannedMaintenanceItem

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let when = record.when {
                        Label(
                            when.formatted(as: "yyyy-MM-dd"),
                            systemImage: "calendar"
                        )
                        .font(.caption)
                        .foregroundColor(Date() > when ? .red : .secondary)
                    }

                    if let odometer = record.odometer {
                        Label(
                            "\(odometer.formatted()) km",
                            systemImage: "speedometer"
                        )
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct DocumentPreviewRow: SwiftUI.View {

    let document: CarDocument

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: CarDocument.iconName(for: document.fileType))
                .font(.title3)
                .foregroundColor(CarDocument.iconColor(for: document.fileType))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(document.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct IdeaPreviewRow: SwiftUI.View {

    let idea: Idea

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let host = idea.hostName {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption2)
                        Text(host)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                } else if let desc = idea.descriptionText, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct CarInfoContent: SwiftUI.View {

    let car: Car

    var body: some SwiftUI.View {
        VStack(spacing: 0) {
            CarInfoRow(
                icon: "road.lanes",
                label: L("Current (km)"),
                value: "\(car.currentMileage.formatted()) km"
            )

            Divider().padding(.leading, 56)

            CarInfoRow(
                icon: "gauge.with.dots.needle.bottom.50percent",
                label: L("Total mileage"),
                value: "\(car.getTotalMileage().formatted()) km"
            )

            if let front = car.frontWheelSize, !front.isEmpty {
                Divider().padding(.leading, 56)

                CarInfoRow(
                    icon: "circle.circle",
                    label: L("Front wheel size"),
                    value: front
                )

                if let rear = car.rearWheelSize, !rear.isEmpty, rear != front {
                    Divider().padding(.leading, 56)

                    CarInfoRow(
                        icon: "circle.circle",
                        label: L("Rear wheel size"),
                        value: rear
                    )
                }
            }
        }
    }
}

private struct CarInfoRow: SwiftUI.View {

    let icon: String
    let label: String
    let value: String

    var body: some SwiftUI.View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32, height: 32)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct EmptySectionView: SwiftUI.View {

    let icon: String
    let message: String

    var body: some SwiftUI.View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.gray.opacity(0.5))
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            Spacer()
        }
    }
}
