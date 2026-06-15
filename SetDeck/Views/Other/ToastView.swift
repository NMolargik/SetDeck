//
//  ToastView.swift
//  SetDeck
//
//  Created by Nick Molargik on 6/14/26.
//
//  Top-of-screen toast rendering for ToastManager.
//

import SwiftUI

struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void

    var body: some View {
        toastContent
            .padding(.horizontal, Brand.Space.lg)
            .frame(maxWidth: 320)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isStaticText)
    }

    @ContentBuilder
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

struct ToastContainerModifier: ViewModifier {
    @Environment(ToastManager.self) private var toastManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
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
    func toastContainer() -> some View {
        modifier(ToastContainerModifier())
    }
}
