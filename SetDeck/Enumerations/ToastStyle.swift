//
//  ToastStyle.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//

import SwiftUI

enum ToastStyle {
    case error
    case success
    case info

    /// Brand tint used for the toast's glass/background.
    var tint: Color {
        switch self {
        case .error: .red
        case .success: .greenStart
        case .info: .blueStart
        }
    }

    var iconName: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}
