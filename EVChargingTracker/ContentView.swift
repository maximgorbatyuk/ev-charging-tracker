import SwiftUI
@_exported import SQLite

// Resolve naming conflict between SwiftUI.View and SQLite.View
typealias SQLiteView = SQLite.View

// MARK: - Models
struct ChargingSession: Identifiable {
    var id: Int64?
    var date: Date
    var energyCharged: Double
    var chargerType: ChargerType
    var odometer: Int
    var cost: Double?
    var notes: String
}

enum ChargerType: String, CaseIterable, Codable {
    case home7kW = "Home (7kW)"
    case home11kW = "Home (11kW)"
    case destination22kW = "Destination (22kW)"
    case superchargerV2 = "Supercharger V2 (150kW)"
    case superchargerV3 = "Supercharger V3 (250kW)"
    case superchargerV4 = "Supercharger V4 (350kW)"
    case publicFast50kW = "Public Fast (50kW)"
    case publicRapid100kW = "Public Rapid (100kW)"
}

// MARK: - Database Manager
class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: Connection?
    
    // Table definition
    private let sessions = Table("charging_sessions")
    private let id = Expression<Int64>("id")
    private let date = Expression<Date>("date")
    private let energyCharged = Expression<Double>("energy_charged")
    private let chargerType = Expression<String>("charger_type")
    private let odometer = Expression<Int>("odometer")
    private let cost = Expression<Double?>("cost")
    private let notes = Expression<String>("notes")
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            
            let dbPath = "\(path)/tesla_charging.sqlite3"
            print("Database path: \(dbPath)")
            
            db = try Connection(dbPath)
            createTable()
        } catch {
            print("Unable to setup database: \(error)")
        }
    }
    
    private func createTable() {
        guard let db = db else { return }
        
        do {
            try db.run(sessions.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(date)
                t.column(energyCharged)
                t.column(chargerType)
                t.column(odometer)
                t.column(cost)
                t.column(notes)
            })
            print("Table created successfully")
        } catch {
            print("Unable to create table: \(error)")
        }
    }
    
    // CRUD Operations
    func insertSession(_ session: ChargingSession) -> Int64? {
        guard let db = db else { return nil }
        
        do {
            let insert = sessions.insert(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes
            )
            
            let rowId = try db.run(insert)
            print("Inserted session with id: \(rowId)")
            return rowId
        } catch {
            print("Insert failed: \(error)")
            return nil
        }
    }
    
    func fetchAllSessions() -> [ChargingSession] {
        guard let db = db else { return [] }
        
        var sessionsList: [ChargingSession] = []
        
        do {
            for session in try db.prepare(sessions.order(date.desc)) {
                let chargerTypeEnum = ChargerType(rawValue: session[chargerType]) ?? .home7kW
                
                let chargingSession = ChargingSession(
                    id: session[id],
                    date: session[date],
                    energyCharged: session[energyCharged],
                    chargerType: chargerTypeEnum,
                    odometer: session[odometer],
                    cost: session[cost],
                    notes: session[notes]
                )
                sessionsList.append(chargingSession)
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        return sessionsList
    }
    
    func updateSession(_ session: ChargingSession) -> Bool {
        guard let db = db, let sessionId = session.id else { return false }
        
        let sessionToUpdate = sessions.filter(id == sessionId)
        
        do {
            try db.run(sessionToUpdate.update(
                date <- session.date,
                energyCharged <- session.energyCharged,
                chargerType <- session.chargerType.rawValue,
                odometer <- session.odometer,
                cost <- session.cost,
                notes <- session.notes
            ))
            print("Updated session with id: \(sessionId)")
            return true
        } catch {
            print("Update failed: \(error)")
            return false
        }
    }
    
    func deleteSession(id sessionId: Int64) -> Bool {
        guard let db = db else { return false }
        
        let sessionToDelete = sessions.filter(id == sessionId)
        
        do {
            try db.run(sessionToDelete.delete())
            print("Deleted session with id: \(sessionId)")
            return true
        } catch {
            print("Delete failed: \(error)")
            return false
        }
    }
    
    func getTotalEnergy() -> Double {
        guard let db = db else { return 0 }
        
        do {
            let total = try db.scalar(sessions.select(energyCharged.sum))
            return total ?? 0
        } catch {
            print("Failed to get total energy: \(error)")
            return 0
        }
    }
    
    func getTotalCost() -> Double {
        guard let db = db else { return 0 }
        
        do {
            let total = try db.scalar(sessions.select(cost.sum))
            return total ?? 0
        } catch {
            print("Failed to get total cost: \(error)")
            return 0
        }
    }
    
    func getSessionCount() -> Int {
        guard let db = db else { return 0 }
        
        do {
            return try db.scalar(sessions.count)
        } catch {
            print("Failed to get session count: \(error)")
            return 0
        }
    }
}

// MARK: - View Model
class ChargingViewModel: ObservableObject {
    @Published var sessions: [ChargingSession] = []
    
    private let dbManager = DatabaseManager.shared
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        sessions = dbManager.fetchAllSessions()
    }
    
    func addSession(_ session: ChargingSession) {
        if let id = dbManager.insertSession(session) {
            var newSession = session
            newSession.id = id
            sessions.insert(newSession, at: 0)
        }
    }
    
    func deleteSession(_ session: ChargingSession) {
        guard let sessionId = session.id else { return }
        
        if dbManager.deleteSession(id: sessionId) {
            sessions.removeAll { $0.id == sessionId }
        }
    }
    
    func updateSession(_ session: ChargingSession) {
        if dbManager.updateSession(session) {
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
        return totalEnergy / Double(sessions.count)
    }
    
    var totalCost: Double {
        sessions.compactMap { $0.cost }.reduce(0, +)
    }
}

// MARK: - Main View
struct ContentView: SwiftUICore.View {
    @StateObject private var viewModel = ChargingViewModel()
    @State private var showingAddSession = false
    
    var body: some SwiftUICore.View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats Cards
                        statsView
                        
                        // Add Button
                        Button(action: {
                            showingAddSession = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Charging Session")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Sessions List
                        if viewModel.sessions.isEmpty {
                            emptyStateView
                        } else {
                            sessionsListView
                        }
                        
                        // Total Cost
                        if viewModel.totalCost > 0 {
                            totalCostView
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Tesla Charging")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddSession) {
                AddSessionView(viewModel: viewModel)
            }
        }
    }
    
    private var statsView: some SwiftUICore.View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Energy",
                value: String(format: "%.1f kWh", viewModel.totalEnergy),
                icon: "bolt.fill",
                color: .yellow
            )
            
            StatCard(
                title: "Avg/Session",
                value: String(format: "%.1f kWh", viewModel.averageEnergy),
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            StatCard(
                title: "Sessions",
                value: "\(viewModel.sessions.count)",
                icon: "gauge.high",
                color: .blue
            )
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some SwiftUICore.View {
        VStack(spacing: 16) {
            Image(systemName: "battery.100.bolt")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No charging sessions yet")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("Add your first session to start tracking")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(.top, 60)
    }
    
    private var sessionsListView: some SwiftUICore.View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.sessions) { session in
                SessionCard(session: session, onDelete: {
                    viewModel.deleteSession(session)
                })
            }
        }
        .padding(.horizontal)
    }
    
    private var totalCostView: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Charging Cost")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(String(format: "$%.2f", viewModel.totalCost))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Stat Card
struct StatCard: SwiftUICore.View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Session Card
struct SessionCard: SwiftUICore.View {
    let session: ChargingSession
    let onDelete: () -> Void
    
    var body: some SwiftUICore.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(session.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            Text(session.chargerType.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .cornerRadius(12)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Energy")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(String(format: "%.1f", session.energyCharged)) kWh")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.yellow)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Odometer")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(session.odometer.formatted()) km")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                if let cost = session.cost {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cost")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "$%.2f", cost))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
            }
            
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Add Session View
struct AddSessionView: SwiftUICore.View {
    @ObservedObject var viewModel: ChargingViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var date = Date()
    @State private var energyCharged = ""
    @State private var chargerType: ChargerType = .home7kW
    @State private var odometer = ""
    @State private var cost = ""
    @State private var notes = ""
    @State private var showingAlert = false
    
    var body: some SwiftUICore.View {
        NavigationView {
            Form {
                Section(header: Text("Session Details")) {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    HStack {
                        Text("Energy (kWh)")
                        Spacer()
                        TextField("45.2", text: $energyCharged)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Charger Type", selection: $chargerType) {
                        ForEach(ChargerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Odometer (km)")
                        Spacer()
                        TextField("12345", text: $odometer)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Optional")) {
                    HStack {
                        Text("Cost")
                        Spacer()
                        TextField("12.50", text: $cost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Add Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Invalid Input", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter valid values for Energy and Odometer.")
            }
        }
    }
    
    private func saveSession() {
        guard let energy = Double(energyCharged),
              let odo = Int(odometer) else {
            showingAlert = true
            return
        }
        
        let sessionCost = Double(cost)
        
        let session = ChargingSession(
            date: date,
            energyCharged: energy,
            chargerType: chargerType,
            odometer: odo,
            cost: sessionCost,
            notes: notes
        )
        
        viewModel.addSession(session)
        dismiss()
    }
}
