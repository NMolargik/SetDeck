//
//  AppLinks.swift
//  SetDeckCore
//
//  Outbound links for rating and sharing SetDeck. The `ct` parameter attributes installs
//  to the place the link was shared from.
//

import Foundation

nonisolated public enum AppLinks {
    /// Opens the App Store's write-a-review page directly.
    public static let writeReview = URL(string: "https://apps.apple.com/app/id6484503374?action=write-review")!
    /// What "Share SetDeck" in Settings hands to the share sheet.
    public static let shareApp = URL(string: "https://molargiksoftware.com/go/setdeck?ct=share_app")!
    /// Appended to the workout summary share message.
    public static let shareSummary = URL(string: "https://molargiksoftware.com/go/setdeck?ct=share_summary")!
}
