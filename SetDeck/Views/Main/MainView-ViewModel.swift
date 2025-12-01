//
//  MainView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import Foundation
//
//  MainView-ViewModel.swift
//  Stork
//
//  Created by Nick Molargik on 10/27/25.
//

import SwiftUI
import WeatherKit

extension MainView {
    @Observable
    class ViewModel {
        // MARK: - UI State (moved from View)
        var appTab: AppTab = .routine
        var showingEntrySheet: Bool = false
        var showingSettingsSheet: Bool = false
        var showingHospitalSheet: Bool = false
        var listPath = NavigationPath()
        var now: Date = Date()
        var drawOn: Bool = false

        // MARK: - Actions (moved from View)
        func handleAddTapped() {
            showingEntrySheet = true
        }

//        func updateDelivery(delivery: Delivery, reviewScene: UIWindowScene?, deliveryManager: DeliveryManager) {
//            // If the delivery already exists (has babies array or is present in manager), treat as update is handled by caller elsewhere; otherwise create.
//            if deliveryManager.deliveries.contains(where: { $0.id == delivery.id }) {
//                // Do nothing here; updates are handled at the call site that passes an existing model and uses deliveryManager.update
//                return
//            } else {
//                deliveryManager.create(delivery: delivery, reviewScene: reviewScene)
//            }
//            showingEntrySheet = false
//        }
    }
}
