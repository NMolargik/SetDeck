//
//  Log.swift
//  SetDeckCore
//
//  One os.Logger per subsystem category. Never `print` — files calling `Log`
//  need their own `import os` (MemberImportVisibility).
//

import Foundation
import os

nonisolated public enum Log {
    private static let subsystem = "com.molargiksoftware.SetDeck"

    public static let app = Logger(subsystem: subsystem, category: "App")
    public static let workouts = Logger(subsystem: subsystem, category: "Workouts")
    public static let achievements = Logger(subsystem: subsystem, category: "Achievements")
    public static let health = Logger(subsystem: subsystem, category: "Health")
    public static let sync = Logger(subsystem: subsystem, category: "CloudSync")
    public static let connectivity = Logger(subsystem: subsystem, category: "Connectivity")
    public static let spotlight = Logger(subsystem: subsystem, category: "Spotlight")
    public static let widgets = Logger(subsystem: subsystem, category: "Widgets")
}
