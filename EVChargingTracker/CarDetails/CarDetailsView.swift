//
//  CarDetailsView.swift
//  EVChargingTracker
//
//  Created by Maxim Gorbatyuk on 01.03.2026.
//

import SwiftUI

struct CarDetailsView: SwiftUI.View {

    let onPlannedMaintenaceRecordsUpdated: () -> Void

    var body: some SwiftUI.View {
        CarDetailsFlowContainerView(
            onPlannedMaintenaceRecordsUpdated: onPlannedMaintenaceRecordsUpdated
        )
    }
}
