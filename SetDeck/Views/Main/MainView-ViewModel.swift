//
//  MainView-ViewModel.swift
//  SetDeck
//
//  Created by Nick Molargik on 11/13/25.
//

import SwiftUI

extension MainView {
    @Observable
    class ViewModel {
        var appTab: AppTab = .routine
        var showingEditRoutineSheet: Bool = false
    }
}
