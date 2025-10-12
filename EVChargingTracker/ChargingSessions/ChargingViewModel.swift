//
//  ChargingViewModel.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 11.10.2025.
//

import Foundation

class ChargingViewModel: ObservableObject {
    @Published var sessions: [ChargingSession] = []

    let defaultCurrency: Currency
    
    private let db: DatabaseManager
    private let chargingSessionsRepository: ChargingSessionsRepository

    init() {
        
        self.db = DatabaseManager.shared
        self.chargingSessionsRepository = db.chargingSessionsRepository!
        self.defaultCurrency = .kzt

        loadSessions()
    }

    func loadSessions() {
        sessions = chargingSessionsRepository.fetchAllSessions()
    }

    func addSession(_ session: ChargingSession) {
        if let id = chargingSessionsRepository.insertSession(session) {
            var newSession = session
            newSession.id = id
            sessions.insert(newSession, at: 0)
        }
    }
    
    func deleteSession(_ session: ChargingSession) {
        guard let sessionId = session.id else { return }
        
        if chargingSessionsRepository.deleteSession(id: sessionId) {
            sessions.removeAll { $0.id == sessionId }
        }
    }
    
    func updateSession(_ session: ChargingSession) {
        if chargingSessionsRepository.updateSession(session) {
            if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                sessions[index] = session
            }
            loadSessions() // Reload to get proper sorting
        }
    }
    
    var totalEnergy: Double {
        sessions.reduce(0) { $0 + $1.energyCharged }
    }
    
    var averageEnergy: Double {
        guard !sessions.isEmpty else { return 0 }
        
        let sessionsToCount = sessions.filter({ $0.isInitialRecord == false }).count
        return totalEnergy / Double(sessionsToCount)
    }
    
    var totalCost: Double {
        sessions.compactMap { $0.cost }.reduce(0, +)
    }
}
