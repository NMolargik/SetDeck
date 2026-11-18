//
//  Company.swift
//  SetDeckCore
//
//  The publisher's name, website and support address: the one place the app reads them
//  from. These are text people read, not identifiers; the shipping identifiers
//  (bundle, App Group, iCloud container) stay `com.molargiksoftware.*` and never change.
//

import Foundation

nonisolated public enum Company {
    public static let name = "Farside Software"
    public static let legalName = "Farside Software LLC"
    /// Site root, no trailing slash.
    public static let siteBase = "https://farsidesoftware.com"
    public static let supportEmail = "support@farsidesoftware.com"

    public static var website: URL { URL(string: siteBase)! }
    public static func page(_ path: String) -> URL { URL(string: siteBase + path)! }

    /// The app's page, support page and privacy policy on the site.
    public static var appPage: URL { page("/setdeck") }
    public static var support: URL { page("/support") }
    public static var privacy: URL { page("/privacy") }
}
