//
//  DocumentsRepository.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

@_exported import SQLite
import Foundation
import os

protocol DocumentsRepositoryProtocol {
    func getAllRecords(carId: Int64) -> [CarDocument]
    func getLatestRecords(carId: Int64, limit: Int) -> [CarDocument]
    func getRecordsCount(carId: Int64) -> Int
    func insertRecord(_ record: CarDocument) -> Int64?
    func updateRecord(_ record: CarDocument) -> Bool
    func deleteRecord(id recordId: Int64) -> Bool
    func deleteRecordsForCar(_ carId: Int64)
}

class DocumentsRepository: DocumentsRepositoryProtocol {
    private let table: Table

    private let id = Expression<Int64>("id")
    private let carIdColumn = Expression<Int64>("car_id")
    private let customTitleColumn = Expression<String?>("custom_title")
    private let fileNameColumn = Expression<String>("file_name")
    private let filePathColumn = Expression<String?>("file_path")
    private let fileTypeColumn = Expression<String>("file_type")
    private let fileSizeColumn = Expression<Int64>("file_size")
    private let createdAtColumn = Expression<Date>("created_at")
    private let updatedAtColumn = Expression<Date>("updated_at")

    private var db: Connection
    private let logger: Logger

    init(db: Connection, tableName: String, logger: Logger? = nil) {
        self.db = db
        self.table = Table(tableName)
        self.logger = logger ?? Logger(subsystem: tableName, category: "Database")
    }

    func getCreateTableCommand() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(carIdColumn)
            t.column(customTitleColumn)
            t.column(fileNameColumn)
            t.column(filePathColumn)
            t.column(fileTypeColumn)
            t.column(fileSizeColumn)
            t.column(createdAtColumn)
            t.column(updatedAtColumn)
        }
    }

    func getCreateIndexCommands() -> [String] {
        return [
            table.createIndex(carIdColumn, ifNotExists: true),
            table.createIndex(createdAtColumn, ifNotExists: true)
        ]
    }

    func getAllRecords(carId: Int64) -> [CarDocument] {
        var records: [CarDocument] = []
        do {
            for row in try db.prepare(table.filter(carIdColumn == carId).order(createdAtColumn.desc)) {
                records.append(mapRow(row))
            }
        } catch {
            logger.error("Fetch all documents failed: \(error)")
        }
        return records
    }

    func getLatestRecords(carId: Int64, limit: Int) -> [CarDocument] {
        var records: [CarDocument] = []
        do {
            let query = table
                .filter(carIdColumn == carId)
                .order(createdAtColumn.desc)
                .limit(limit)
            for row in try db.prepare(query) {
                records.append(mapRow(row))
            }
        } catch {
            logger.error("Fetch latest documents failed: \(error)")
        }
        return records
    }

    func getRecordsCount(carId: Int64) -> Int {
        do {
            return try db.scalar(table.filter(carIdColumn == carId).count)
        } catch {
            logger.error("Documents count failed: \(error)")
            return 0
        }
    }

    func insertRecord(_ record: CarDocument) -> Int64? {
        do {
            let rowId = try db.run(table.insert(
                carIdColumn <- record.carId,
                customTitleColumn <- record.customTitle,
                fileNameColumn <- record.fileName,
                filePathColumn <- record.filePath,
                fileTypeColumn <- record.fileType,
                fileSizeColumn <- record.fileSize,
                createdAtColumn <- record.createdAt,
                updatedAtColumn <- record.updatedAt
            ))
            return rowId
        } catch {
            logger.error("Insert document failed: \(error)")
            return nil
        }
    }

    func updateRecord(_ record: CarDocument) -> Bool {
        guard let recordId = record.id else {
            logger.error("Update document failed: id is nil")
            return false
        }
        do {
            try db.run(table.filter(id == recordId).update(
                customTitleColumn <- record.customTitle,
                fileNameColumn <- record.fileName,
                filePathColumn <- record.filePath,
                fileTypeColumn <- record.fileType,
                fileSizeColumn <- record.fileSize,
                updatedAtColumn <- Date()
            ))
            return true
        } catch {
            logger.error("Update document failed: \(error)")
            return false
        }
    }

    func deleteRecord(id recordId: Int64) -> Bool {
        do {
            try db.run(table.filter(id == recordId).delete())
            return true
        } catch {
            logger.error("Delete document failed: \(error)")
            return false
        }
    }

    func deleteRecordsForCar(_ carId: Int64) {
        do {
            try db.run(table.filter(carIdColumn == carId).delete())
        } catch {
            logger.error("Delete documents for car failed: \(error)")
        }
    }

    func truncateTable() {
        do {
            try db.run(table.delete())
        } catch {
            logger.error("Truncate documents failed: \(error)")
        }
    }

    private func mapRow(_ row: Row) -> CarDocument {
        CarDocument(
            id: row[id],
            carId: row[carIdColumn],
            customTitle: row[customTitleColumn],
            fileName: row[fileNameColumn],
            filePath: row[filePathColumn],
            fileType: row[fileTypeColumn],
            fileSize: row[fileSizeColumn],
            createdAt: row[createdAtColumn],
            updatedAt: row[updatedAtColumn]
        )
    }
}
