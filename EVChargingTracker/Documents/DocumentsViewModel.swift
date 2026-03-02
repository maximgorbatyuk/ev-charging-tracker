//
//  DocumentsViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation
import PhotosUI
import SwiftUI

@MainActor
class DocumentsViewModel: ObservableObject {

    @Published var documents: [CarDocument] = []

    private let documentsRepo: DocumentsRepositoryProtocol?
    private let carRepo: CarRepositoryProtocol?
    private let documentService: DocumentService
    private let analytics: AnalyticsService

    private var selectedCar: Car?

    init(
        db: DatabaseManagerProtocol = DatabaseManager.shared,
        documentService: DocumentService = .shared,
        analytics: AnalyticsService = .shared
    ) {
        self.documentsRepo = db.getDocumentsRepository()
        self.carRepo = db.getCarRepository()
        self.documentService = documentService
        self.analytics = analytics
        loadData()
    }

    func loadData() {
        selectedCar = carRepo?.getSelectedForExpensesCar()
        guard let car = selectedCar, let carId = car.id else {
            documents = []
            return
        }
        documents = documentsRepo?.getAllRecords(carId: carId) ?? []
    }

    func importFile(from url: URL, customTitle: String?) {
        guard let car = selectedCar, let carId = car.id else { return }

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let fileName = url.lastPathComponent
        let fileType = documentService.detectFileType(fileName: fileName)

        guard let savedURL = documentService.copyFile(from: url, fileName: fileName, carId: carId) else {
            return
        }

        let size = documentService.fileSize(at: savedURL.path)
        let doc = CarDocument(
            carId: carId,
            customTitle: customTitle,
            fileName: fileName,
            filePath: savedURL.path,
            fileType: fileType,
            fileSize: size
        )

        _ = documentsRepo?.insertRecord(doc)
        analytics.trackEvent("document_added", properties: [
            "screen": "documents_list",
            "file_type": fileType
        ])
        loadData()
    }

    func importImageData(_ data: Data, fileName: String, customTitle: String?) {
        guard let car = selectedCar, let carId = car.id else { return }

        let fileType = documentService.detectFileType(fileName: fileName)

        guard let savedURL = documentService.saveFile(data: data, fileName: fileName, carId: carId) else {
            return
        }

        let size = documentService.fileSize(at: savedURL.path)
        let doc = CarDocument(
            carId: carId,
            customTitle: customTitle,
            fileName: fileName,
            filePath: savedURL.path,
            fileType: fileType,
            fileSize: size
        )

        _ = documentsRepo?.insertRecord(doc)
        analytics.trackEvent("document_added", properties: [
            "screen": "documents_list",
            "file_type": fileType
        ])
        loadData()
    }

    func deleteDocument(_ document: CarDocument) {
        guard let docId = document.id else { return }

        if let path = document.filePath {
            documentService.deleteFile(at: path)
        }

        _ = documentsRepo?.deleteRecord(id: docId)
        analytics.trackEvent("document_deleted", properties: ["screen": "documents_list"])
        loadData()
    }

    func renameDocument(_ document: CarDocument, newTitle: String) {
        let updated = document
        updated.customTitle = newTitle.isEmpty ? nil : newTitle
        _ = documentsRepo?.updateRecord(updated)
        loadData()
    }
}
