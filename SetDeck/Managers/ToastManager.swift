//
//  ToastManager.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//
//  Lightweight top-of-screen toasts (pattern shared with Stork/Mygra/Opalite).
//  Used for background iCloud sync status instead of a blocking screen.
//  Rendering lives in Views/Other/ToastView.swift.
//

import SwiftUI

// MARK: - Toast Item

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let icon: String?
    let duration: TimeInterval

    init(message: String, style: ToastStyle = .info, icon: String? = nil, duration: TimeInterval = 3.0) {
        self.message = message
        self.style = style
        self.icon = icon
        self.duration = duration
    }

    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@MainActor
@Observable
final class ToastManager {
    private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    func show(_ toast: ToastItem) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = toast
        }

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(toast.duration))
            if !Task.isCancelled {
                dismiss()
            }
        }
    }

    func show(message: String, style: ToastStyle = .info, icon: String? = nil) {
        show(ToastItem(message: message, style: style, icon: icon))
    }

    func showSuccess(_ message: String) {
        show(ToastItem(message: message, style: .success))
    }

    func show(error: any LocalizedError) {
        show(ToastItem(message: error.errorDescription ?? "An error occurred", style: .error))
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = nil
        }
    }
}
