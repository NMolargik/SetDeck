//
//  Toast.swift
//  SetDeckDesignSystem
//
//  Lightweight top-of-screen toasts: style, item, manager, rendering, and the
//  `.toastContainer()` overlay (used for background iCloud sync status, achievement
//  errors, and general feedback instead of blocking screens).
//

import SwiftUI

// MARK: - Toast Style

public enum ToastStyle: Sendable {
    case error
    case success
    case info

    /// Brand tint used for the toast's glass/background.
    public var tint: Color {
        switch self {
        case .error: .red
        case .success: .greenStart
        case .info: .blueStart
        }
    }

    public var iconName: String {
        switch self {
        case .error: "xmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .info: "info.circle.fill"
        }
    }
}

// MARK: - Toast Item

public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let style: ToastStyle
    public let icon: String?
    public let duration: TimeInterval

    public init(message: String, style: ToastStyle = .info, icon: String? = nil, duration: TimeInterval = 3.0) {
        self.message = message
        self.style = style
        self.icon = icon
        self.duration = duration
    }

    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast Manager

@MainActor
@Observable
public final class ToastManager {
    public private(set) var currentToast: ToastItem?
    private var dismissTask: Task<Void, Never>?

    public init() {}

    public func show(_ toast: ToastItem) {
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

    public func show(message: String, style: ToastStyle = .info, icon: String? = nil) {
        show(ToastItem(message: message, style: style, icon: icon))
    }

    public func showSuccess(_ message: String) {
        show(ToastItem(message: message, style: .success))
    }

    public func show(error: any LocalizedError) {
        show(ToastItem(message: error.errorDescription ?? String(localized: "An error occurred"), style: .error))
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentToast = nil
        }
    }
}

#if os(iOS)

// MARK: - Toast View

public struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void

    public init(toast: ToastItem, onDismiss: @escaping () -> Void) {
        self.toast = toast
        self.onDismiss = onDismiss
    }

    public var body: some View {
        toastContent
            .padding(.horizontal, Brand.Space.lg)
            .frame(maxWidth: 320)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }

    @ViewBuilder
    private var toastContent: some View {
        if #available(iOS 26.0, *) {
            toastBody
                .foregroundStyle(.white)
                .padding(.horizontal, Brand.Space.lg)
                .padding(.vertical, Brand.Space.md)
                .glassEffect(.regular.tint(toast.style.tint).interactive())
        } else {
            toastBody
                .foregroundStyle(.white)
                .padding(.horizontal, Brand.Space.lg)
                .padding(.vertical, Brand.Space.md)
                .background(
                    Capsule(style: .continuous)
                        .fill(toast.style.tint.gradient)
                        .shadow(color: toast.style.tint.opacity(0.35), radius: 10, y: 4)
                )
        }
    }

    private var toastBody: some View {
        HStack(spacing: Brand.Space.md) {
            Image(systemName: toast.icon ?? toast.style.iconName)
                .font(.title3)
                .fontWeight(.semibold)
                .accessibilityHidden(true)

            Text(toast.message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Button {
                Haptics.lightImpact()
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(6)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
    }
}

// MARK: - Toast Container Modifier

public struct ToastContainerModifier: ViewModifier {
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init() {}

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: horizontalSizeClass == .regular ? .topLeading : .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast) {
                        toastManager.dismiss()
                    }
                    .id(toast.id)
                    .padding(.horizontal, Brand.Space.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
    }
}

extension View {
    public func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}
#endif
