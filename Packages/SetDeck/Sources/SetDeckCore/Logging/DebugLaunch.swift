//
//  DebugLaunch.swift
//  SetDeckCore
//
//  DEBUG-only launch arguments that drive screens into a given state for screenshot
//  vetting without touch input (`-sdDay 3`, `-sdSettingsPage about`, …). Compiled out of
//  shipping builds.
//

#if DEBUG
import Foundation

nonisolated public enum DebugLaunch {
    /// Value following `name` in the launch arguments, if present.
    public static func value(_ name: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    public static func int(_ name: String) -> Int? { value(name).flatMap(Int.init) }

    /// Running under `-uiTesting` (sample data, clean screenshots).
    public static var isUITesting: Bool { flag("-uiTesting") }

    public static func flag(_ name: String) -> Bool { ProcessInfo.processInfo.arguments.contains(name) }
}
#endif
