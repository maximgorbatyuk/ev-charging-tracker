import SwiftUI
import Charts

struct ChargingConsumptionLineChart: SwiftUI.View {

    var viewModel: ChargingConsumptionChartViewModel
    let data: ChargingConsumptionLineChartData
    let analytics: AnalyticsService

    init(data: ChargingConsumptionLineChartData) {
        self.data = data
        self.viewModel = ChargingConsumptionChartViewModel(data: data)
        self.analytics = data.analytics
    }

    var body: some SwiftUI.View {
        AppCard(pad: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.hasData {
                    Text(String(format: L("%.1f kWh/month average"), viewModel.overallAverage))
                        .appFont(.footnote)
                        .foregroundColor(AppColors.inkSoft)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                } else {
                    Chart {
                        ForEach(viewModel.monthlyData) { data in
                            LineMark(
                                x: .value("Month", data.monthName),
                                y: .value("Charging", data.totalEnergy)
                            )
                            .foregroundStyle(AppColors.orange)
                            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Month", data.monthName),
                                y: .value("Charging", data.totalEnergy)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.orange.opacity(0.28),
                                        AppColors.orange.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Month", data.monthName),
                                y: .value("Charging", data.totalEnergy)
                            )
                            .foregroundStyle(AppColors.orange)
                            .symbolSize(20)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text(String(format: "%.1f", doubleValue))
                                        .appFont(.caption)
                                        .foregroundColor(AppColors.inkSoft)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let stringValue = value.as(String.self) {
                                    Text(stringValue)
                                        .appFont(.caption)
                                        .foregroundColor(AppColors.inkSoft)
                                }
                            }
                        }
                    }
                    .chartYAxisLabel("kWh", position: .leading)
                    .frame(height: 220)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }
            }
        }
        .onAppear {
            viewModel.loadMonthlyConsumption()
            analytics.trackEvent("charging_consumption_chart_viewed", properties: [:])
        }
    }
}
