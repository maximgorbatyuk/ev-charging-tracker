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
                                y: .value("Charging", data.totalEnergy),
                                series: .value("Series", "charging")
                            )
                            .foregroundStyle(AppColors.green)
                            .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Month", data.monthName),
                                y: .value("Charging", data.totalEnergy)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppColors.green.opacity(0.28),
                                        AppColors.green.opacity(0)
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
                            .foregroundStyle(AppColors.green)
                            .symbolSize(20)
                        }

                        if viewModel.hasFuelData {
                            ForEach(viewModel.monthlyData) { data in
                                LineMark(
                                    x: .value("Month", data.monthName),
                                    y: .value("Fuel", data.totalFuelVolume * viewModel.fuelScale),
                                    series: .value("Series", "fuel")
                                )
                                .foregroundStyle(AppColors.purple)
                                .lineStyle(StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Month", data.monthName),
                                    y: .value("Fuel", data.totalFuelVolume * viewModel.fuelScale)
                                )
                                .foregroundStyle(AppColors.purple)
                                .symbolSize(20)
                            }
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

                        if viewModel.hasFuelData {
                            AxisMarks(position: .trailing) { value in
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text(String(format: "%.0f", doubleValue / viewModel.fuelScale))
                                            .appFont(.caption)
                                            .foregroundColor(AppColors.purple)
                                    }
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
                    .chartYAxisLabel(viewModel.hasFuelData ? data.volumeUnitLabel : "", position: .trailing)
                    .frame(height: 220)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                }

                if viewModel.hasFuelData {
                    chartLegend
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
            }
        }
        .onAppear {
            viewModel.loadMonthlyConsumption()
            analytics.trackEvent("charging_consumption_chart_viewed", properties: [:])
        }
    }

    @ViewBuilder
    private var chartLegend: some SwiftUI.View {
        HStack(spacing: 16) {
            legendItem(color: AppColors.green, label: ExpenseType.charging.localizedName)
            legendItem(color: AppColors.purple, label: ExpenseType.fuel.localizedName)
            Spacer()
        }
    }

    private func legendItem(color: Color, label: String) -> some SwiftUI.View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .appFont(.caption2)
                .foregroundColor(AppColors.inkSoft)
        }
    }
}
