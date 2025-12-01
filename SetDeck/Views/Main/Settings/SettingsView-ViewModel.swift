//
//  SettingsView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/19/25.
//

import Foundation

extension SettingsView {
    @Observable
    class ViewModel {
        var showDeleteConfirmation: Bool = false
        var showHistoryClearedAlert: Bool = false
        var appVersion: String {
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        }
    }
}
