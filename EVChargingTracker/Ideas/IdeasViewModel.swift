//
//  IdeasViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import Foundation

@MainActor
class IdeasViewModel: ObservableObject {

    @Published var ideas: [Idea] = []

    private let ideasRepo: IdeasRepositoryProtocol?
    private let carRepo: CarRepositoryProtocol?
    private let analytics: AnalyticsService

    private var selectedCar: Car?

    init(db: DatabaseManagerProtocol = DatabaseManager.shared, analytics: AnalyticsService = .shared) {
        self.ideasRepo = db.getIdeasRepository()
        self.carRepo = db.getCarRepository()
        self.analytics = analytics
        loadData()
    }

    func loadData() {
        selectedCar = carRepo?.getSelectedForExpensesCar()
        guard let car = selectedCar, let carId = car.id else {
            ideas = []
            return
        }
        ideas = ideasRepo?.getAllRecords(carId: carId) ?? []
    }

    func addIdea(title: String, url: String?, descriptionText: String?) {
        guard let car = selectedCar, let carId = car.id else { return }

        let idea = Idea(
            carId: carId,
            title: title,
            url: url,
            descriptionText: descriptionText
        )

        _ = ideasRepo?.insertRecord(idea)
        analytics.trackEvent("idea_added", properties: ["screen": "ideas_list"])
        loadData()
    }

    func updateIdea(_ idea: Idea) {
        _ = ideasRepo?.updateRecord(idea)
        analytics.trackEvent("idea_updated", properties: ["screen": "ideas_list"])
        loadData()
    }

    func deleteIdea(_ idea: Idea) {
        guard let ideaId = idea.id else { return }
        _ = ideasRepo?.deleteRecord(id: ideaId)
        analytics.trackEvent("idea_deleted", properties: ["screen": "ideas_list"])
        loadData()
    }
}
