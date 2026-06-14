//
//  DeepLinkTests.swift
//  SetDeckTests
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation
import Testing
@testable import SetDeck

@Suite("DeepLink Tests")
struct DeepLinkTests {

    @Test("Parses valid setdeck:// hosts",
          arguments: [
            ("setdeck://routine", DeepLink.routine),
            ("setdeck://stats", DeepLink.stats),
            ("setdeck://settings", DeepLink.settings)
          ])
    func parsesValidHosts(urlString: String, expected: DeepLink) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLink(url: url) == expected)
    }

    @Test("Rejects unknown scheme, host, or empty",
          arguments: [
            "https://routine",
            "setdeck://unknown",
            "setdeck://",
            "foo://stats"
          ])
    func rejectsInvalid(urlString: String) throws {
        let url = try #require(URL(string: urlString))
        #expect(DeepLink(url: url) == nil)
    }

    @Test("Every case round-trips through its url")
    func roundTrips() {
        for link in DeepLink.allCases {
            #expect(DeepLink(url: link.url) == link)
        }
    }
}
