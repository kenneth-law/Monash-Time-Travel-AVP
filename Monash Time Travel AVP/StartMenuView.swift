//
//  StartMenuView.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI

struct StartMenuView: View {

    let selectedSceneTitle: String
    let onToggleScene: () -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack {
            // Frosted backdrop over the scene
            backdrop
                .ignoresSafeArea()

            VStack(spacing: 48) {

                // MARK: - Title
                VStack(spacing: 8) {
                    Text("MONASH")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.7)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                    Text("TIME TRAVEL")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(white: 0.85))
                        .kerning(6)
                }

                // MARK: - Buttons
                VStack(spacing: 16) {
                    MenuButton(title: "Scene: \(selectedSceneTitle)", action: onToggleScene)

                    MenuButton(title: "Start Game", isPrimary: true, action: onStart)

                    #if os(macOS)
                    MenuButton(title: "Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    #elseif os(iOS)
                    MenuButton(title: "Quit") {
                        exit(0)
                    }
                    #endif
                }
            }
            .padding(64)
        }
    }
}

private extension StartMenuView {
    @ViewBuilder
    var backdrop: some View {
        #if os(macOS)
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.82),
                        Color.gray.opacity(0.55)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        #else
        Rectangle()
            .fill(.ultraThinMaterial)
        #endif
    }
}

// MARK: - Reusable menu button

private struct MenuButton: View {

    let title: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(isPrimary ? Color.black : Color.white)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(
                    isPrimary
                        ? AnyShapeStyle(Color.white)
                        : AnyShapeStyle(Color.white.opacity(0.15))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(isPrimary ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StartMenuView(
        selectedSceneTitle: "Hong Kong",
        onToggleScene: {},
        onStart: {}
    )
}
