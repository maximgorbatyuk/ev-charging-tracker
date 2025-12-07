import SwiftUI
import Charts

struct ChargingConsumptionLineChart: SwiftUI.View {
    @StateObject private var viewModel = ChargingConsumptionChartViewModel()

    let expenses: [Expense]
    let analytics: AnalyticsService
    let monthsCount: Int
    
    var body: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Average Consumption Trend"))
                    .font(.headline)
                    .fontWeight(.bold)
                
                if viewModel.hasData {
                    Text(String(format: "%.1f kWh/month average", viewModel.overallAverage))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else if !viewModel.hasData {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text(L("No charing data available"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(L("Add charging sessions to see trends"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            } else {
                // Chart
                Chart {
                    ForEach(viewModel.monthlyData) { data in
                        LineMark(
                            x: .value("Month", data.monthName),
                            y: .value("Charging", data.averageChargeSession)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.orange, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Month", data.monthName),
                            y: .value("Charging", data.averageChargeSession)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.orange.opacity(0.3),
                                    Color.red.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Month", data.monthName),
                            y: .value("Charging", data.averageChargeSession)
                        )
                        .foregroundStyle(Color.orange)
                        .symbolSize(60)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(String(format: "%.1f", doubleValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let stringValue = value.as(String.self) {
                                Text(stringValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .chartYAxisLabel("kWh/100km", position: .leading)
                .frame(height: 220)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.loadMonthlyConsumption(expenses: expenses, monthsCount: monthsCount)
            analytics.trackEvent("charging_consumption_chart_viewed", properties: [:])
        }
    }
}

#Preview {
    ChargingConsumptionLineChart(
        expenses: [],
        analytics: AnalyticsService.shared,
        monthsCount: 6
    )
}
