//
//  CarDto.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 24.10.2025.
//

import Foundation

struct CarDto: Identifiable {
    let id: Int64?
    let name: String
    let selectedForTracking: Bool
    let batteryCapacity: Double?
    let currentMileage: Int // in km
    let initialMileage: Int // in km
    let expenseCurrency: Currency
    let frontWheelSize: String?
    let rearWheelSize: String?
}
