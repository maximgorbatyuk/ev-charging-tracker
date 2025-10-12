import SwiftUI

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

                        // Total Cost
                        if viewModel.totalCost > 0 {
                            totalCostView
                        }
                        
                        // Sessions List
                        if viewModel.sessions.isEmpty {
                            emptyStateView
                        } else {
                            sessionsListView
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Car Charging")
            .navigationBarTitleDisplayMode(.automatic)
            .sheet(isPresented: $showingAddSession) {
                AddSessionView(viewModel: viewModel, defaultCurrency: viewModel.defaultCurrency)
            }
        }
    }
    
    private var statsView: some SwiftUICore.View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Energy",
                value: String(format: "%.1f kWh", viewModel.totalEnergy),
                icon: "bolt.fill",
                color: .yellow,
                minHeight: 90
            )
            
            StatCard(
                title: "Avg/Session",
                value: String(format: "%.1f kWh", viewModel.averageEnergy),
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                minHeight: 90
            )
            
            StatCard(
                title: "Sessions",
                value: "\(viewModel.sessions.count)",
                icon: "gauge.high",
                color: .blue,
                minHeight: 90
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
                SessionCard(
                    session: session,
                    onDelete: {
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

            Text(String(format: "\(viewModel.defaultCurrency.rawValue)%.2f", viewModel.totalCost))
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
