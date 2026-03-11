//
//  TimeTravelControls.swift
//  Monash Time Travel AVP
//
//  Created by Codex on 11/3/2026.
//

import SwiftUI

struct DestinationSelectorView: View {
    let selectedScene: MenuScene
    let onSelectScene: (MenuScene) -> Void
    var compact: Bool = false

    var body: some View {
        let columns = compact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]

        LazyVGrid(columns: columns, spacing: compact ? 10 : 14) {
            ForEach(MenuScene.allCases, id: \.self) { scene in
                Button(action: { onSelectScene(scene) }) {
                    VStack(alignment: .leading, spacing: compact ? 8 : 10) {
                        Text(scene.shortCode)
                            .font(.system(size: compact ? 11 : 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(scene.title)
                            .font(.system(size: compact ? 16 : 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(scene.subtitle)
                            .font(.system(size: compact ? 11 : 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(compact ? 2 : 3)
                    }
                    .frame(maxWidth: .infinity, minHeight: compact ? 108 : 126, alignment: .topLeading)
                    .padding(compact ? 14 : 16)
                    .background(cardBackground(for: scene))
                    .overlay(
                        RoundedRectangle(cornerRadius: compact ? 18 : 22)
                            .strokeBorder(.white.opacity(selectedScene == scene ? 0.55 : 0.12), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: compact ? 18 : 22))
                }
                .buttonStyle(.plain)
                #if !os(macOS)
                .hoverEffect(.lift)
                #endif
            }
        }
    }

    @ViewBuilder
    private func cardBackground(for scene: MenuScene) -> some View {
        let palette = scene.palette
        let selected = scene == selectedScene
        let opacity = selected ? 0.95 : 0.72

        LinearGradient(
            colors: [
                Color(red: Double(palette.primary.x), green: Double(palette.primary.y), blue: Double(palette.primary.z)).opacity(opacity),
                Color(red: Double(palette.secondary.x), green: Double(palette.secondary.y), blue: Double(palette.secondary.z)).opacity(selected ? 0.8 : 0.48)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct TimeScrubberView: View {
    let year: Int
    let onYearChange: (Int) -> Void
    var compact: Bool = false

    private var sliderBinding: Binding<Double> {
        Binding(
            get: { TimeTravelSelection.scrubberPosition(forYear: year) },
            set: { onYearChange(TimeTravelSelection.snappedYear(forScrubberPosition: $0)) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 12 : 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chronoline")
                        .font(.system(size: compact ? 12 : 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.62))
                    Text(TimeTravelSelection.format(year: year))
                        .font(.system(size: compact ? 28 : 40, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Spacer()

                Text(label(for: year))
                    .font(.system(size: compact ? 12 : 14, weight: .semibold, design: .rounded))
                    .padding(.horizontal, compact ? 10 : 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
                    .foregroundStyle(.white.opacity(0.88))
            }

            Slider(
                value: sliderBinding,
                in: 0.0...1.0
            )
            .tint(.white)

            HStack {
                Text(TimeTravelSelection.format(year: TimeTravelSelection.minYear))
                Spacer()
                Text("1970")
                Spacer()
                Text(TimeTravelSelection.format(year: TimeTravelSelection.maxYear))
            }
            .font(.system(size: compact ? 10 : 11, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.55))

            HStack(spacing: compact ? 8 : 10) {
                ForEach(TimeTravelSelection.quickJumpYears, id: \.self) { quickYear in
                    Button(TimeTravelSelection.format(year: quickYear)) {
                        onYearChange(quickYear)
                    }
                    .buttonStyle(TimeChipButtonStyle(isSelected: quickYear == year))
                    #if !os(macOS)
                    .hoverEffect(.highlight)
                    #endif
                }
            }
        }
    }

    private func label(for year: Int) -> String {
        switch year {
        case 2000...:
            return "Near Future"
        case 1961...1999:
            return "Founding Era"
        case 0...1960:
            return "Pre-Campus"
        default:
            return "Ancient Terrain"
        }
    }
}

private struct TimeChipButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.white.opacity(isSelected ? 0.88 : (configuration.isPressed ? 0.18 : 0.1)))
            )
            .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.9))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
