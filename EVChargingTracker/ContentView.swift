import SwiftUI
@_exported import SQLite

// Resolve naming conflict between SwiftUI.View and SQLite.View
typealias SQLiteView = SQLite.View

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
            .navigationTitle("Car Charging")
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
