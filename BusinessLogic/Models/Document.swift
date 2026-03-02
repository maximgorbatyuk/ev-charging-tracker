//
//  Document.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import SwiftUI

class CarDocument: Identifiable, Codable {
    var id: Int64?
    var carId: Int64
    var customTitle: String?
    var fileName: String
    var filePath: String?
    var fileType: String
    var fileSize: Int64
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int64? = nil,
        carId: Int64,
        customTitle: String? = nil,
        fileName: String,
        filePath: String? = nil,
        fileType: String,
        fileSize: Int64,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.carId = carId
        self.customTitle = customTitle
        self.fileName = fileName
        self.filePath = filePath
        self.fileType = fileType
        self.fileSize = fileSize
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }

    var displayTitle: String {
        customTitle ?? fileName
    }

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var fileExtension: String {
        (fileName as NSString).pathExtension.uppercased()
    }

    static func iconName(for fileType: String) -> String {
        switch fileType.lowercased() {
        case "pdf": return "doc.richtext"
        case "jpg", "jpeg": return "photo"
        case "png": return "photo.artframe"
        case "heic": return "photo.fill"
        default: return "doc"
        }
    }

    static func iconColor(for fileType: String) -> Color {
        switch fileType.lowercased() {
        case "pdf": return .red
        case "jpg", "jpeg", "png", "heic": return .blue
        default: return .gray
        }
    }
}
