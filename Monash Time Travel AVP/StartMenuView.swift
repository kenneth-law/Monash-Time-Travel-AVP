//
//  StartMenuView.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI

struct StartMenuView: View {
    let selection: TimeTravelSelection
    let onSelectScene: (MenuScene) -> Void
    let onYearChange: (Int) -> Void
    let onStart: () -> Void

    var body: some View {
        ZStack {
            backdrop
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MONASH TIME PORTAL")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))

                    Text("Travel from 2026 back to 10000 BC")
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text("Choose a destination, scrub the chronoline, and preview how the campus dissolves from contemporary massing into ancient terrain.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(maxWidth: 680, alignment: .leading)
                }

                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Destination")
                            .sectionLabel()
                        DestinationSelectorView(
                            selectedScene: selection.scene,
                            onSelectScene: onSelectScene
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 18) {
                        Text("Time Vector")
                            .sectionLabel()
                        TimeScrubberView(
                            year: selection.clampedYear,
                            onYearChange: onYearChange
                        )
                        statusCard
                        controlRow
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                }
            }
            .padding(36)
            .frame(maxWidth: 1100)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selection.eraTitle)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))
            Text(selection.scene.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(selection.eraDescription)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            MenuButton(title: "Start Journey", isPrimary: true, action: onStart)

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
}

private extension Text {
    func sectionLabel() -> some View {
        self
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.58))
            .textCase(.uppercase)
    }
}

private extension StartMenuView {
    @ViewBuilder
    var backdrop: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.10).opacity(0.96),
                Color(red: 0.07, green: 0.09, blue: 0.16).opacity(0.90),
                Color(red: 0.18, green: 0.05, blue: 0.04).opacity(0.82)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(.white.opacity(0.10))
                .blur(radius: 80)
                .frame(width: 280, height: 280)
                .offset(x: -40, y: -60)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(red: 0.97, green: 0.60, blue: 0.18).opacity(0.18))
                .blur(radius: 100)
                .frame(width: 340, height: 340)
                .offset(x: 80, y: 90)
        }
    }
}

private struct MenuButton: View {
    let title: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(isPrimary ? Color.black : Color.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .frame(minWidth: 148)
                .background(backgroundStyle)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white.opacity(isPrimary ? 0 : 0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        #if !os(macOS)
        .hoverEffect(.highlight)
        #endif
    }

    @ViewBuilder
    private var backgroundStyle: some View {
        if isPrimary {
            LinearGradient(
                colors: [Color.white, Color(red: 0.98, green: 0.73, blue: 0.33)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.white.opacity(0.08)
        }
    }
}

#Preview {
    StartMenuView(
        selection: TimeTravelSelection(),
        onSelectScene: { _ in },
        onYearChange: { _ in },
        onStart: {}
    )
}
