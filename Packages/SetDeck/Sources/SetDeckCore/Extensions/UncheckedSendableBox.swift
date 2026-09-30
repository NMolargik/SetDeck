//
//  UncheckedSendableBox.swift
//  SetDeckCore
//
//  Wraps a value that is not statically `Sendable` so it can be transferred into a
//  `Task` or across an isolation boundary under the Swift 6 language mode.
//
//  Use this only for values whose access is already serialized in practice — for
//  example a WidgetKit `TimelineProvider` completion handler (invoked exactly once) or
//  an ActivityKit `Activity` handle that is only mutated through a single owner. It
//  documents an intentional, audited escape hatch rather than silencing the diagnostic
//  at the call site.
//

import Foundation

nonisolated public struct UncheckedSendableBox<Value>: @unchecked Sendable {
    public let value: Value

    public init(value: Value) {
        self.value = value
    }
}
