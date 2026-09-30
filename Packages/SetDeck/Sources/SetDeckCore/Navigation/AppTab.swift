//
//  AppTab.swift
//  SetDeckCore
//
//  The four main tabs. Icon/color styling lives in SetDeckDesignSystem.
//

import Foundation

nonisolated public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case routine = "Routine"
    case stats = "Stats"
    case health = "Health"
    case settings = "Settings"

    public var id: String { self.rawValue }
}
