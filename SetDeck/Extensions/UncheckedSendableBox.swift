//
//  UncheckedSendableBox.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//

import Foundation

/// Wraps a value that is not statically `Sendable` so it can be transferred
/// into a `Task` or across an isolation boundary under the Swift 6 language
/// mode.
///
/// Use this only for values whose access is already serialized in practice —
/// for example a WidgetKit `TimelineProvider` completion handler (invoked
/// exactly once) or an ActivityKit `Activity` handle that is only mutated
/// through a single owner. It documents an intentional, audited escape hatch
/// rather than silencing the diagnostic at the call site.
nonisolated struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(value: Value) {
        self.value = value
    }
}
