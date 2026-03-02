//
//  Migration_20260301_CreateDocumentsTable.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

@_exported import SQLite
import Foundation
import os

final class Migration_20260301_CreateDocumentsAndIdeasTables {
    private let migrationName = "20260301_CreateDocumentsAndIdeasTables"
    private let db: Connection

    init(db: Connection) {
        self.db = db
    }

    func execute() {
        let logger = Logger()

        // Create documents table
        let documentsRepository = DocumentsRepository(
            db: db,
            tableName: DatabaseManager.DocumentsTableName
        )

        do {
            let createCommand = documentsRepository.getCreateTableCommand()
            try db.run(createCommand)

            for indexCommand in documentsRepository.getCreateIndexCommands() {
                try db.run(indexCommand)
            }

            logger.debug("Documents table created successfully")
        } catch {
            logger.error("Unable to create documents table in migration \(self.migrationName): \(error)")
        }

        // Create ideas table
        let ideasRepository = IdeasRepository(
            db: db,
            tableName: DatabaseManager.IdeasTableName
        )

        do {
            let createCommand = ideasRepository.getCreateTableCommand()
            try db.run(createCommand)

            for indexCommand in ideasRepository.getCreateIndexCommands() {
                try db.run(indexCommand)
            }

            logger.debug("Ideas table created successfully")
        } catch {
            logger.error("Unable to create ideas table in migration \(self.migrationName): \(error)")
        }
    }
}
