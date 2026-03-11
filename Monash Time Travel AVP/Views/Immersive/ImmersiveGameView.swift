#if os(visionOS)
//
//  ImmersiveGameView.swift
//  Monash Time Travel AVP
//
//  Created by Codex on 11/3/2026.
//

import SwiftUI
import RealityKit

struct ImmersiveGameView: View {
    @State private var runtime = GameRuntime()
    @State private var selection: TimeTravelSelection

    private final class SceneRefs {
        var worldRoot: Entity?
        var destinationRoot: Entity?
        var skyDome: Entity?
        var imageBasedLight: Entity?
    }

    @MainActor
    private final class GameRuntime {
        let player = PlayerController()
        let envManager = EnvironmentManager()
        let scene = SceneRefs()
        var isSceneReady = false
        var environmentResource: EnvironmentResource?
        var visibleSkyTexture: TextureResource?
        var updateSubscription: EventSubscription?
        var sceneLoadTask: Task<Void, Never>?
    }

    init(selection: TimeTravelSelection) {
        _selection = State(initialValue: selection)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RealityView { content in
                setupScene(content: content)
            } update: { _ in
            }
            .focusable()
            .preferredSurroundingsEffect(.dark)

            overlayPanel
        }
        .onAppear {
            runtime.player.clearInput()
            runtime.player.position = [0, runtime.player.eyeHeight, 0]
        }
        .onDisappear {
            runtime.player.clearInput()
            runtime.updateSubscription?.cancel()
            runtime.updateSubscription = nil
            runtime.sceneLoadTask?.cancel()
            runtime.sceneLoadTask = nil
            runtime.isSceneReady = false
        }
        .onChange(of: selection) { _, _ in
            guard runtime.isSceneReady else { return }
            rebuildDestination()
        }
        .onKeyPress(phases: .down) { press in
            runtime.player.setSprinting(press.modifiers.contains(.shift))
            if let char = press.characters.first {
                runtime.player.keyDown(char)
            }
            return .handled
        }
        .onKeyPress(phases: .up) { press in
            runtime.player.setSprinting(press.modifiers.contains(.shift))
            if let char = press.characters.first {
                runtime.player.keyUp(char)
            }
            return .handled
        }
    }

    private func setupScene(content: any RealityViewContentProtocol) {
        guard runtime.scene.worldRoot == nil else { return }

        let worldRoot = Entity()
        worldRoot.name = "immersiveWorldRoot"
        content.add(worldRoot)
        runtime.scene.worldRoot = worldRoot

        let destinationRoot = Entity()
        destinationRoot.name = "immersiveDestinationRoot"
        worldRoot.addChild(destinationRoot)
        runtime.scene.destinationRoot = destinationRoot

        let environmentRoot = Entity()
        environmentRoot.name = "immersiveEnvironmentRoot"
        worldRoot.addChild(environmentRoot)
        runtime.envManager.setRoot(environmentRoot)

        let skyDome = Entity()
        skyDome.name = "skyDome"
        content.add(skyDome)
        runtime.scene.skyDome = skyDome

        let imageBasedLight = Entity()
        imageBasedLight.name = "imageBasedLight"
        content.add(imageBasedLight)
        runtime.scene.imageBasedLight = imageBasedLight

        runtime.updateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
            updateScene(deltaTime: Float(min(event.deltaTime, 0.1)))
        }
        runtime.isSceneReady = true
        loadScene()
    }

    private func updateScene(deltaTime dt: Float) {
        guard dt > 0 else { return }

        let newPosition = runtime.player.update(deltaTime: dt)
        let displacement = newPosition - SIMD3<Float>(0, runtime.player.eyeHeight, 0)
        runtime.scene.worldRoot?.position = SIMD3<Float>(-displacement.x, 0, -displacement.z)
    }

    private func loadScene() {
        guard runtime.isSceneReady else { return }

        runtime.sceneLoadTask?.cancel()
        runtime.sceneLoadTask = Task { @MainActor in
            runtime.player.clearInput()
            runtime.player.position = [0, runtime.player.eyeHeight, 0]
            runtime.scene.worldRoot?.position = .zero
            runtime.envManager.clearAll()

            do {
                let environment = try runtime.envManager.loadEnvironmentResource(name: "clarens_midday_4k")
                runtime.environmentResource = environment
                applySkyDome(using: try loadVisibleSkyTexture())
                applyImageBasedLighting(using: environment)
            } catch is CancellationError {
                return
            } catch {
                print("[ImmersiveGameView] Failed to load immersive environment: \(error)")
            }

            rebuildDestination()
        }
    }

    private func rebuildDestination() {
        guard let destinationRoot = runtime.scene.destinationRoot else { return }

        for child in Array(destinationRoot.children) {
            child.removeFromParent()
        }

        let placeholder = PlaceholderSceneBuilder.makeScene(for: selection, interactive: true)
        destinationRoot.position = selection.scene.immersivePosition
        destinationRoot.addChild(placeholder)
    }

    private func loadVisibleSkyTexture() throws -> TextureResource {
        if let cached = runtime.visibleSkyTexture {
            return cached
        }

        do {
            let texture = try TextureResource.load(named: "clarens_midday_4k_visible", in: .main)
            runtime.visibleSkyTexture = texture
            return texture
        } catch {
            let texture = try TextureResource.load(named: "clarens_midday_4k_visible.jpg", in: .main)
            runtime.visibleSkyTexture = texture
            return texture
        }
    }

    private func applySkyDome(using texture: TextureResource) {
        guard let skyDome = runtime.scene.skyDome else { return }

        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))

        skyDome.components.set(ModelComponent(
            mesh: .generateSphere(radius: 300),
            materials: [material]
        ))
        skyDome.scale = [-1, 1, 1]
        skyDome.position = .zero
    }

    private func applyImageBasedLighting(using environment: EnvironmentResource) {
        guard
            let lightEntity = runtime.scene.imageBasedLight,
            let worldRoot = runtime.scene.worldRoot
        else {
            return
        }

        lightEntity.components.set(ImageBasedLightComponent(source: .single(environment), intensityExponent: 1.0))
        worldRoot.components.set(ImageBasedLightReceiverComponent(imageBasedLight: lightEntity))
    }

    private var overlayPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TIME PORTAL CONTROL")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.62))

            DestinationSelectorView(
                selectedScene: selection.scene,
                onSelectScene: { selection.scene = $0 },
                compact: true
            )

            TimeScrubberView(
                year: selection.clampedYear,
                onYearChange: { selection.year = $0 },
                compact: true
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(selection.eraTitle)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                Text(selection.eraDescription)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
            }
        }
        .padding(18)
        .frame(width: 360, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(22)
    }
}
#endif
