//
//  Idea.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation

class Idea: Identifiable, Codable {
    var id: Int64?
    var carId: Int64
    var title: String
    var url: String?
    var descriptionText: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int64? = nil,
        carId: Int64,
        title: String,
        url: String? = nil,
        descriptionText: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.carId = carId
        self.title = title
        self.url = url
        self.descriptionText = descriptionText
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }

    var hostName: String? {
        guard let urlString = url,
              let parsed = URL(string: urlString),
              let host = parsed.host
        else { return nil }
        return host
    }
}
