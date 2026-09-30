// swift-tools-version: 6.2
//
//  Package.swift
//  SetDeck
//
//  The umbrella package holding the whole app: pure domain (Core), persistence (Data),
//  system-framework services (Services), the design system, one module per feature, and
//  the composition root. The app/widget/watch targets are thin shells over these products.
//

import PackageDescription

let isolation: [SwiftSetting] = [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "SetDeck",
    defaultLocalization: "en",
    // Match the app targets' floors (iOS 18 / watchOS 11); macOS is the host `swift test` floor.
    platforms: [.iOS("18.0"), .watchOS("11.0"), .macOS("15.0")],
    products: [
        .library(name: "SetDeckCore", targets: ["SetDeckCore"]),
        .library(name: "SetDeckData", targets: ["SetDeckData"]),
        .library(name: "SetDeckServices", targets: ["SetDeckServices"]),
        .library(name: "SetDeckDesignSystem", targets: ["SetDeckDesignSystem"]),
        .library(name: "SetDeckFeatureShared", targets: ["SetDeckFeatureShared"]),
        .library(name: "SetDeckFeatureRoutine", targets: ["SetDeckFeatureRoutine"]),
        .library(name: "SetDeckFeatureStats", targets: ["SetDeckFeatureStats"]),
        .library(name: "SetDeckFeatureHealth", targets: ["SetDeckFeatureHealth"]),
        .library(name: "SetDeckFeatureSettings", targets: ["SetDeckFeatureSettings"]),
        .library(name: "SetDeckFeatureOnboarding", targets: ["SetDeckFeatureOnboarding"]),
        .library(name: "SetDeckComposition", targets: ["SetDeckComposition"]),
    ],
    targets: [
        .target(
            name: "SetDeckCore",
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckData",
            dependencies: ["SetDeckCore"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckServices",
            dependencies: ["SetDeckCore"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckDesignSystem",
            dependencies: ["SetDeckCore"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureShared",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureRoutine",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem", "SetDeckFeatureShared"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureStats",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem", "SetDeckServices", "SetDeckFeatureShared"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureHealth",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem", "SetDeckServices", "SetDeckFeatureShared"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureSettings",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem", "SetDeckServices", "SetDeckFeatureShared"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckFeatureOnboarding",
            dependencies: ["SetDeckCore", "SetDeckDesignSystem", "SetDeckServices", "SetDeckFeatureShared", "SetDeckFeatureRoutine"],
            swiftSettings: isolation
        ),
        .target(
            name: "SetDeckComposition",
            dependencies: [
                "SetDeckCore", "SetDeckData", "SetDeckServices", "SetDeckDesignSystem",
                "SetDeckFeatureShared", "SetDeckFeatureRoutine", "SetDeckFeatureStats",
                "SetDeckFeatureHealth", "SetDeckFeatureSettings", "SetDeckFeatureOnboarding",
            ],
            swiftSettings: isolation
        ),
        .testTarget(name: "SetDeckCoreTests", dependencies: ["SetDeckCore"], swiftSettings: isolation),
        .testTarget(name: "SetDeckDataTests", dependencies: ["SetDeckData"], swiftSettings: isolation),
        .testTarget(name: "SetDeckServicesTests", dependencies: ["SetDeckServices"], swiftSettings: isolation),
        .testTarget(name: "SetDeckFeatureSharedTests", dependencies: ["SetDeckFeatureShared"], swiftSettings: isolation),
        .testTarget(name: "SetDeckFeatureRoutineTests", dependencies: ["SetDeckFeatureRoutine"], swiftSettings: isolation),
        .testTarget(name: "SetDeckFeatureStatsTests", dependencies: ["SetDeckFeatureStats"], swiftSettings: isolation),
        .testTarget(name: "SetDeckFeatureHealthTests", dependencies: ["SetDeckFeatureHealth"], swiftSettings: isolation),
        .testTarget(name: "SetDeckFeatureSettingsTests", dependencies: ["SetDeckFeatureSettings"], swiftSettings: isolation),
        .testTarget(name: "SetDeckCompositionTests", dependencies: ["SetDeckComposition"], swiftSettings: isolation),
    ]
)
