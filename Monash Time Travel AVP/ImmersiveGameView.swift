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
    let selectedScene: MenuScene

    @State private var runtime = GameRuntime()

    private final class SceneRefs {
        var worldRoot: Entity?
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

    var body: some View {
        RealityView { content in
            setupScene(content: content)
        } update: { _ in
        }
        .focusable()
        .preferredSurroundingsEffect(.dark)
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
        .onChange(of: selectedScene) { _, _ in
            guard runtime.isSceneReady else { return }
            loadScene()
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

        let scene = selectedScene

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

                try await runtime.envManager.loadFromBundle(
                    name: scene.assetName,
                    id: scene.assetID,
                    position: scene.immersivePosition,
                    scale: scene.scale
                )
            } catch is CancellationError {
                return
            } catch {
                print("[ImmersiveGameView] Failed to load immersive scene '\(scene.title)': \(error)")
            }
        }
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
}
#endif
