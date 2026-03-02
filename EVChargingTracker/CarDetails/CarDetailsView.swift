//
//  CarDetailsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct CarDetailsView: SwiftUI.View {

    let onPlannedMaintenanceRecordsUpdated: () -> Void

    var body: some SwiftUI.View {
        CarDetailsFlowContainerView(
            onPlannedMaintenanceRecordsUpdated: onPlannedMaintenanceRecordsUpdated
        )
    }
}
