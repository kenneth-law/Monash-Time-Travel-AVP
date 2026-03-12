//
//  TimeTravelExperience.swift
//  Monash Time Travel AVP
//
//  Created by Codex on 11/3/2026.
//

import SwiftUI
import RealityKit
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
#else
import UIKit
typealias PlatformColor = UIColor
#endif

struct TimeTravelSelection: Codable, Hashable {
    static let minYear = -10_000
    static let maxYear = 2026
    static let pivotYear = 1970
    static let modernScaleShare = 0.5
    static let quickJumpYears = [2026, 1961, 1850, -10_000]

    static let snapYears: [Int] = {
        var anchors = Array(stride(from: minYear, through: pivotYear, by: 10))
        anchors.append(contentsOf: [1980, 1990, 2000, 2010, 2020, maxYear])
        return Array(Set(anchors)).sorted()
    }()

    var scene: MenuScene = .campusCentre
    var year: Int = maxYear

    var clampedYear: Int {
        min(max(year, Self.minYear), Self.maxYear)
    }

    var normalizedProgress: Float {
        let span = Float(Self.maxYear - Self.minYear)
        return Float(clampedYear - Self.minYear) / span
    }

    var formattedYear: String {
        Self.format(year: clampedYear)
    }

    var scrubberPosition: Double {
        Self.scrubberPosition(forYear: clampedYear)
    }

    var eraTitle: String {
        switch clampedYear {
        case 2000...:
            return "Near Future"
        case 1961...1999:
            return "Early Monash"
        case 0...1960:
            return "Colonial Ground"
        default:
            return "Ancient Plain"
        }
    }

    var eraDescription: String {
        switch clampedYear {
        case 2000...:
            return "Dense campus massing and active social core."
        case 1961...1999:
            return "Institutional forms emerge as the campus is founded."
        case 0...1960:
            return "Human traces thin out and the built footprint recedes."
        default:
            return "Only land markers remain before modern settlement."
        }
    }

    static func format(year: Int) -> String {
        if year < 0 {
            return "\(abs(year)) BC"
        }
        if year == 0 {
            return "0"
        }
        return "\(year)"
    }

    static func scrubberPosition(forYear year: Int) -> Double {
        let clamped = min(max(year, minYear), maxYear)

        if clamped <= pivotYear {
            let span = Double(pivotYear - minYear)
            let progress = Double(clamped - minYear) / span
            return progress * modernScaleShare
        }

        let span = Double(maxYear - pivotYear)
        let progress = Double(clamped - pivotYear) / span
        return modernScaleShare + progress * (1.0 - modernScaleShare)
    }

    static func year(forScrubberPosition position: Double) -> Int {
        let clamped = min(max(position, 0.0), 1.0)

        if clamped <= modernScaleShare {
            let local = clamped / modernScaleShare
            let year = Double(minYear) + local * Double(pivotYear - minYear)
            return Int(year.rounded())
        }

        let local = (clamped - modernScaleShare) / (1.0 - modernScaleShare)
        let year = Double(pivotYear) + local * Double(maxYear - pivotYear)
        return Int(year.rounded())
    }

    static func snappedYear(forScrubberPosition position: Double) -> Int {
        let rawYear = year(forScrubberPosition: position)
        let rawPosition = scrubberPosition(forYear: rawYear)

        guard
            let nearestAnchor = snapYears.min(by: {
                abs(scrubberPosition(forYear: $0) - rawPosition) < abs(scrubberPosition(forYear: $1) - rawPosition)
            })
        else {
            return rawYear
        }

        let anchorPosition = scrubberPosition(forYear: nearestAnchor)
        let snapThreshold = nearestAnchor >= pivotYear ? 0.03 : 0.015

        if abs(anchorPosition - rawPosition) <= snapThreshold {
            return nearestAnchor
        }

        return rawYear
    }
}

enum MenuScene: String, CaseIterable, Codable, Hashable {
    case campusCentre
    case ltb
    case alanFinkelBuilding
    case lemonScentedLawn

    var title: String {
        switch self {
        case .campusCentre:
            return "Campus Centre"
        case .ltb:
            return "LTB"
        case .alanFinkelBuilding:
            return "Alan Finkel Building"
        case .lemonScentedLawn:
            return "Lemon Scented Lawn"
        }
    }

    var subtitle: String {
        switch self {
        case .campusCentre:
            return "Student life hub and civic hub"
        case .ltb:
            return "Learning & Teaching Building with iconic modernist form"
        case .alanFinkelBuilding:
            return "Technical landmark with stepped research massing"
        case .lemonScentedLawn:
            return "Open green threshold and gathering lawn"
        }
    }

    var shortCode: String {
        switch self {
        case .campusCentre:
            return "CC"
        case .ltb:
            return "LTB"
        case .alanFinkelBuilding:
            return "AFB"
        case .lemonScentedLawn:
            return "LSL"
        }
    }

    var position: SIMD3<Float> {
        [0, 0, -14]
    }

    var immersivePosition: SIMD3<Float> {
        [0, -1.75, 0]
    }

    var palette: ScenePalette {
        switch self {
        case .campusCentre:
            return ScenePalette(primary: [0.88, 0.25, 0.18], secondary: [0.96, 0.72, 0.32], accent: [0.98, 0.96, 0.90], ground: [0.19, 0.12, 0.11])
        case .ltb:
            return ScenePalette(primary: [0.19, 0.46, 0.88], secondary: [0.43, 0.82, 0.94], accent: [0.90, 0.97, 0.99], ground: [0.08, 0.15, 0.22])
        case .alanFinkelBuilding:
            return ScenePalette(primary: [0.18, 0.81, 0.59], secondary: [0.88, 0.96, 0.53], accent: [0.96, 1.00, 0.92], ground: [0.08, 0.19, 0.15])
        case .lemonScentedLawn:
            return ScenePalette(primary: [0.55, 0.81, 0.23], secondary: [0.96, 0.94, 0.47], accent: [0.98, 1.00, 0.92], ground: [0.13, 0.22, 0.08])
        }
    }
}

struct ScenePalette {
    let primary: SIMD3<Float>
    let secondary: SIMD3<Float>
    let accent: SIMD3<Float>
    let ground: SIMD3<Float>
}

struct SceneAssetConfiguration {
    let fileName: String
    let scale: Float
    let windowPosition: SIMD3<Float>
    let immersivePosition: SIMD3<Float>

    var fileStem: String {
        URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
    }

    var fileExtension: String {
        URL(fileURLWithPath: fileName).pathExtension
    }
}

extension MenuScene {
    var featuredAsset: SceneAssetConfiguration? {
        switch self {
        case .alanFinkelBuilding:
            return SceneAssetConfiguration(
                fileName: "Full_Gameready_City_Buildings_IV_HongKong.usdz",
                scale: 0.1,
                windowPosition: [0, 0, -8],
                immersivePosition: [0, -1.75, -5]
            )
        case .campusCentre, .ltb, .lemonScentedLawn:
            return nil
        }
    }
}

enum PlaceholderSceneBuilder {
    static func makeScene(for selection: TimeTravelSelection, interactive: Bool) -> Entity {
        let root = Entity()
        root.name = "placeholder.\(selection.scene.rawValue)"

        let progress = selection.normalizedProgress
        let palette = selection.scene.palette

        addGround(to: root, palette: palette, progress: progress)
        addChronoPortal(to: root, palette: palette, progress: progress, interactive: interactive)

        switch selection.scene {
        case .campusCentre:
            addCampusCentre(to: root, palette: palette, progress: progress, interactive: interactive)
        case .ltb:
            addLTB(to: root, palette: palette, progress: progress, interactive: interactive)
        case .alanFinkelBuilding:
            addAlanFinkel(to: root, palette: palette, progress: progress, interactive: interactive)
        case .lemonScentedLawn:
            addLawn(to: root, palette: palette, progress: progress, interactive: interactive)
        }

        addAncientMarkers(to: root, palette: palette, progress: progress)
        return root
    }

    private static func addGround(to root: Entity, palette: ScenePalette, progress: Float) {
        addBox(
            to: root,
            size: [18, 0.05, 18],
            position: [0, -0.025, 0],
            color: color(from: palette.ground, alpha: 1.0)
        )

        let walkwayOpacity = CGFloat(0.18 + progress * 0.42)
        addBox(
            to: root,
            size: [2.4, 0.01, 16],
            position: [0, 0.01, -1],
            color: color(from: palette.secondary, alpha: walkwayOpacity),
            isMetallic: true
        )

        for index in -3...3 {
            let depth = Float(index) * 2.4
            addBox(
                to: root,
                size: [14, 0.01, 0.12],
                position: [0, 0.02, depth],
                color: color(from: palette.accent, alpha: CGFloat(0.08 + progress * 0.12))
            )
        }
    }

    private static func addChronoPortal(to root: Entity, palette: ScenePalette, progress: Float, interactive: Bool) {
        let ringScale = 0.9 + progress * 0.45
        let ringRadius: Float = 3.6 * ringScale
        let yBase: Float = 2.5

        for index in 0..<18 {
            let angle = (Float(index) / 18.0) * (.pi * 2)
            let x = cos(angle) * ringRadius
            let y = yBase + sin(angle) * ringRadius * 0.45

            addBox(
                to: root,
                size: [0.16, 0.32, 0.16],
                position: [x, y, -7.5],
                color: color(from: index.isMultiple(of: 2) ? palette.primary : palette.secondary, alpha: 0.86),
                isMetallic: true,
                interactive: interactive && index.isMultiple(of: 3)
            )
        }

        addBox(
            to: root,
            size: [0.9, 0.9, 0.9],
            position: [0, yBase, -7.5],
            color: color(from: palette.accent, alpha: CGFloat(0.22 + progress * 0.28)),
            isMetallic: true,
            interactive: interactive
        )
    }

    private static func addCampusCentre(to root: Entity, palette: ScenePalette, progress: Float, interactive: Bool) {
        addSteppedMassing(
            to: root,
            xOffsets: [-3.2, -1.4, 0, 1.7, 3.4],
            baseZ: 0,
            widths: [1.4, 1.6, 1.8, 1.6, 1.4],
            depths: [3.6, 4.6, 5.4, 4.6, 3.6],
            maxHeights: [2.2, 3.8, 5.8, 3.8, 2.4],
            palette: palette,
            progress: progress,
            interactive: interactive
        )

        addBox(
            to: root,
            size: [4.6, 0.18, 2.4],
            position: [0, 0.09 + 1.1 * progress, 3.8],
            color: color(from: palette.secondary, alpha: 0.82),
            isMetallic: true
        )
    }

    private static func addLTB(to root: Entity, palette: ScenePalette, progress: Float, interactive: Bool) {
        for lane in 0..<4 {
            let z = Float(lane) * 2.4 - 3.6
            addBox(
                to: root,
                size: [9.0, max(0.25, 0.6 + progress * Float(1.8 + Float(lane) * 0.4)), 1.3],
                position: [0, max(0.125, 0.3 + progress * Float(0.9 + Float(lane) * 0.2)), z],
                color: color(from: lane.isMultiple(of: 2) ? palette.primary : palette.secondary, alpha: 0.92),
                isMetallic: lane.isMultiple(of: 2),
                interactive: interactive && lane == 1
            )
        }

        for beacon in 0..<6 {
            let x = Float(beacon) * 1.8 - 4.5
            addBox(
                to: root,
                size: [0.28, 0.8 + progress * 1.6, 0.28],
                position: [x, 0.4 + progress * 0.8, 4.2],
                color: color(from: palette.accent, alpha: 0.85)
            )
        }
    }

    private static func addAlanFinkel(to root: Entity, palette: ScenePalette, progress: Float, interactive: Bool) {
        addSteppedMassing(
            to: root,
            xOffsets: [-2.8, -1.1, 0.7, 2.5],
            baseZ: -0.8,
            widths: [1.6, 1.8, 1.8, 1.4],
            depths: [2.8, 3.2, 3.0, 2.4],
            maxHeights: [3.0, 5.2, 4.4, 2.8],
            palette: palette,
            progress: progress,
            interactive: interactive
        )

        addBox(
            to: root,
            size: [5.8, 0.2, 1.0],
            position: [0, 2.2 * progress + 0.3, 2.9],
            color: color(from: palette.secondary, alpha: 0.76),
            isMetallic: true,
            interactive: interactive
        )
    }

    private static func addLawn(to root: Entity, palette: ScenePalette, progress: Float, interactive: Bool) {
        for patch in 0..<7 {
            let x = Float(patch) * 2.1 - 6.3
            let depth = sin(Float(patch) * 0.85) * 2.2
            addBox(
                to: root,
                size: [1.4, 0.03, 1.4],
                position: [x, 0.015, depth],
                color: color(from: palette.primary, alpha: CGFloat(0.18 + progress * 0.22))
            )
        }

        addBox(
            to: root,
            size: [6.2, 0.22, 2.4],
            position: [0, 0.11 + progress * 0.7, -1.4],
            color: color(from: palette.secondary, alpha: 0.86),
            isMetallic: true,
            interactive: interactive
        )

        for canopy in 0..<3 {
            let x = Float(canopy) * 3.0 - 3.0
            addBox(
                to: root,
                size: [0.22, 1.6 + progress * 1.4, 0.22],
                position: [x, 0.8 + progress * 0.7, 2.6],
                color: color(from: palette.accent, alpha: 0.72)
            )
            addBox(
                to: root,
                size: [1.8, 0.12, 1.8],
                position: [x, 1.7 + progress * 1.5, 2.6],
                color: color(from: palette.primary, alpha: CGFloat(0.24 + progress * 0.3)),
                interactive: interactive && canopy == 1
            )
        }
    }

    private static func addAncientMarkers(to root: Entity, palette: ScenePalette, progress: Float) {
        let markerStrength = max(0.0, 1.0 - progress * 1.2)
        guard markerStrength > 0 else { return }

        for index in 0..<8 {
            let angle = (Float(index) / 8.0) * (.pi * 2)
            let radius: Float = 5.6
            let x = cos(angle) * radius
            let z = sin(angle) * radius

            addBox(
                to: root,
                size: [0.32, 0.8 + markerStrength * 1.6, 0.32],
                position: [x, 0.4 + markerStrength * 0.8, z],
                color: color(from: palette.accent, alpha: CGFloat(0.28 + markerStrength * 0.5))
            )
        }
    }

    private static func addSteppedMassing(
        to root: Entity,
        xOffsets: [Float],
        baseZ: Float,
        widths: [Float],
        depths: [Float],
        maxHeights: [Float],
        palette: ScenePalette,
        progress: Float,
        interactive: Bool
    ) {
        for index in xOffsets.indices {
            let height = max(0.3, maxHeights[index] * max(0.1, progress))
            let positionY = height / 2
            let colorVector = index.isMultiple(of: 2) ? palette.primary : palette.secondary
            addBox(
                to: root,
                size: [widths[index], height, depths[index]],
                position: [xOffsets[index], positionY, baseZ],
                color: color(from: colorVector, alpha: 0.92),
                isMetallic: index.isMultiple(of: 2),
                interactive: interactive && index == xOffsets.count / 2
            )
        }
    }

    private static func addBox(
        to root: Entity,
        size: SIMD3<Float>,
        position: SIMD3<Float>,
        color: PlatformColor,
        isMetallic: Bool = false,
        interactive: Bool = false
    ) {
        let entity = Entity()
        entity.position = position
        entity.components.set(ModelComponent(
            mesh: .generateBox(size: size),
            materials: [SimpleMaterial(color: color, isMetallic: isMetallic)]
        ))

        if interactive {
            entity.components.set(SpinComponent())
            #if (os(iOS) && !targetEnvironment(simulator)) || os(visionOS)
            entity.components.set(InputTargetComponent())
            entity.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
            entity.components.set(HoverEffectComponent())
            #endif
        }

        root.addChild(entity)
    }

    private static func color(from vector: SIMD3<Float>, alpha: CGFloat) -> PlatformColor {
        PlatformColor(
            red: CGFloat(vector.x),
            green: CGFloat(vector.y),
            blue: CGFloat(vector.z),
            alpha: alpha
        )
    }
}
