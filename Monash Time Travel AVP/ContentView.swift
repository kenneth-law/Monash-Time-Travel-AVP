//
//  ContentView.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    // MARK: - State

    @State private var player = PlayerController()
    @State private var envManager = EnvironmentManager()

    /// The camera entity (macOS / iOS Simulator only).
    /// On visionOS hardware the headset IS the camera — no entity is created.
    @State private var cameraEntity: Entity? = nil

    /// The stationary world root. On visionOS hardware, locomotion is achieved
    /// by translating this entity opposite to player movement.
    @State private var worldRoot: Entity? = nil

    // MARK: - Body

    var body: some View {
        ZStack {
            // TimelineView drives the RealityView update closure at display
            // refresh rate, giving us a per-frame game loop.
            TimelineView(.animation) { timeline in
                RealityView { content in
                    setupScene(content: content)
                } update: { content in
                    updateScene(time: timeline.date)
                }
                .gesture(tapEntityGesture)
                // focusable() is required so .onKeyPress events are delivered.
                .focusable()
                .onKeyPress(phases: .down) { press in
                    if let char = press.characters.first {
                        player.keyDown(char)
                    }
                    return .handled
                }
                .onKeyPress(phases: .up) { press in
                    if let char = press.characters.first {
                        player.keyUp(char)
                    }
                    return .handled
                }
            }

            // HUD overlay
            VStack {
                Spacer()
                Text("WASD — walk   ·   Space — jump")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
    }

    // MARK: - Gesture

    var tapEntityGesture: some Gesture {
        TapGesture()
            .targetedToEntity(where: .has(SpinComponent.self))
            .onEnded { gesture in
                try? spinEntity(gesture.entity)
            }
    }

    // MARK: - Scene Setup (runs once)

    private func setupScene(content: any RealityViewContentProtocol) {

        // ── World root ────────────────────────────────────────────────────────
        // All static scene geometry and dynamic assets live under worldRoot.
        // On visionOS hardware we translate worldRoot for locomotion.
        let root = Entity()
        root.name = "worldRoot"
        content.add(root)
        worldRoot = root

        // ── Ground grid ───────────────────────────────────────────────────────
        let grid = makeGridEntity(halfExtent: 100, spacing: 1.0)
        root.addChild(grid)

        // ── Environment root (dynamic USDZ assets) ────────────────────────────
        let envRoot = Entity()
        envRoot.name = "environmentRoot"
        root.addChild(envRoot)
        envManager.setRoot(envRoot)

        // ── Demo cube (preserved, placed 2 m ahead on the floor) ─────────────
        let boxSize: SIMD3<Float> = [0.2, 0.2, 0.2]
        let boxEntity = Entity()
        boxEntity.components.set([
            ModelComponent(
                mesh: .generateBox(size: boxSize),
                materials: [SimpleMaterial(color: .red, isMetallic: true)]
            ),
            InputTargetComponent(),
            HoverEffectComponent(),
            CollisionComponent(shapes: [.generateBox(size: boxSize)]),
            SpinComponent()
        ])
        boxEntity.position = [0, boxSize.y / 2, -2]
        root.addChild(boxEntity)

        // ── Platform-specific camera / anchoring ──────────────────────────────
        #if os(iOS) && !targetEnvironment(simulator)
        // visionOS hardware: headset = camera; anchor worldRoot to the floor.
        content.camera = .spatialTracking
        let anchorTarget: AnchoringComponent.Target = .plane(
            .horizontal,
            classification: .floor,
            minimumBounds: .one
        )
        root.components.set(AnchoringComponent(anchorTarget))

        #elseif os(macOS) || (os(iOS) && targetEnvironment(simulator))
        // macOS / iOS Simulator: manual perspective camera at eye level.
        let camera = Entity()
        camera.name = "playerCamera"
        camera.components.set(PerspectiveCameraComponent())
        // Start at eye level, facing -Z (into the scene toward the cube).
        camera.position = player.position
        camera.look(at: player.position + SIMD3<Float>(0, 0, -1),
                    from: player.position,
                    relativeTo: nil)
        // Camera is NOT under worldRoot — it moves in absolute world space.
        content.add(camera)
        cameraEntity = camera
        #endif
    }

    // MARK: - Per-Frame Update

    private func updateScene(time: Date) {
        let dt = Float(min(time.timeIntervalSince(player.lastUpdateTime), 0.1))
        player.lastUpdateTime = time
        guard dt > 0 else { return }

        // ── Extract camera yaw for direction-relative movement ────────────────
        #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
        if let cam = cameraEntity {
            let q = cam.orientation
            player.yaw = atan2(
                2 * (q.vector.y * q.vector.w + q.vector.x * q.vector.z),
                1 - 2 * (q.vector.y * q.vector.y + q.vector.z * q.vector.z)
            )
        }
        #endif

        // ── Step physics ──────────────────────────────────────────────────────
        let newPosition = player.update(deltaTime: dt)

        // ── Apply to scene ────────────────────────────────────────────────────
        #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
        cameraEntity?.position = newPosition

        #elseif os(iOS) && !targetEnvironment(simulator)
        // On visionOS hardware: move the world opposite to player displacement
        // to simulate walking while the headset tracks head position.
        let displacement = newPosition - SIMD3<Float>(0, player.eyeHeight, 0)
        worldRoot?.position = SIMD3<Float>(-displacement.x, 0, -displacement.z)
        #endif
    }

    // MARK: - Spin (preserved from original)

    func spinEntity(_ entity: Entity) throws {
        guard let spinComponent = entity.components[SpinComponent.self] else { return }
        let spinAction = SpinAction(revolutions: 1, localAxis: spinComponent.spinAxis)
        let spinAnimation = try AnimationResource.makeActionAnimation(
            for: spinAction,
            duration: 1,
            bindTarget: .transform
        )
        entity.playAnimation(spinAnimation)
    }
}

#Preview {
    ContentView()
}
