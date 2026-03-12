//
//  ContentView.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//
 
import SwiftUI
import RealityKit
#if os(macOS)
import AppKit
#endif
 
// MARK: - Game state
 
enum GameState {
    case menu
    case playing
}
 
// MARK: - ContentView
 
struct ContentView: View {
    #if os(visionOS)
    private static let immersiveSpaceID = "game-space"
    #endif
 
    // MARK: State
 
    @State private var gameState   = GameState.menu
    @State private var runtime     = GameRuntime()
    @State private var selection   = TimeTravelSelection()
 
    private final class SceneRefs {
        var camera: Entity?
        var worldRoot: Entity?
        var destinationRoot: Entity?
    }

    /// Keeps mutable RealityKit and player state out of SwiftUI observation.
    @MainActor
    private final class GameRuntime {
        let player = PlayerController()
        let envManager = EnvironmentManager()
        let scene = SceneRefs()
        var updateSubscription: EventSubscription?
        var sceneLoadTask: Task<Void, Never>?
        var skyboxResource: EnvironmentResource?

        #if os(macOS)
        var keyDownMonitor: Any?
        var keyUpMonitor: Any?
        #endif
    }
 
    /// Previous drag location, used to compute per-frame mouse-look deltas.
    @State private var lastDragLocation: CGPoint? = nil

    #if os(visionOS)
    @State private var immersiveSpaceIsOpen = false
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    #endif
 
    // MARK: Body
 
    var body: some View {
        ZStack {
            #if !os(visionOS)
            sceneView
            #endif
 
            if gameState == .menu {
                StartMenuView(
                    selection: selection,
                    onSelectScene: selectScene,
                    onYearChange: updateYear,
                    onStart: startGame
                )
                .zIndex(1)
            }
 
            if gameState == .playing {
                #if os(visionOS)
                visionStatusPanel
                #else
                gameplayHUD
                #endif
            }
        }
        .onAppear {
            #if os(macOS)
            startKeyboardMonitoring()
            #endif
        }
        .onDisappear {
            runtime.player.clearInput()
            runtime.sceneLoadTask?.cancel()
            runtime.sceneLoadTask = nil
            #if os(macOS)
            stopKeyboardMonitoring()
            #endif
        }
        #if !os(visionOS)
        .onChange(of: selection) { oldValue, newValue in
            if oldValue.scene == newValue.scene, newValue.scene.featuredAsset != nil {
                return
            }
            rebuildWindowScene()
        }
        #endif
    }

    @ViewBuilder
    private var sceneView: some View {
        #if os(visionOS)
        let baseView = RealityView { content in
            setupScene(content: content)
        } update: { _ in
        }
        .gesture(mouseLookGesture)
        .focusable()
        #else
        let baseView = RealityView { content in
            #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
            if let skybox = loadSkyboxResource() {
                content.environment = .skybox(skybox)
            }
            #endif
            setupScene(content: content)
        } update: { _ in
        }
        .gesture(mouseLookGesture)
        .focusable()
        #endif

        #if os(iOS) || os(visionOS)
        baseView
            .simultaneousGesture(tapEntityGesture)
            .onKeyPress(phases: .down) { press in
                guard gameState == .playing else { return .ignored }
                runtime.player.setSprinting(press.modifiers.contains(.shift))
                if let char = press.characters.first { runtime.player.keyDown(char) }
                return .handled
            }
            .onKeyPress(phases: .up) { press in
                runtime.player.setSprinting(press.modifiers.contains(.shift))
                if let char = press.characters.first { runtime.player.keyUp(char) }
                return .handled
            }
        #else
        baseView
        #endif
    }
 
    private var gameplayHUD: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("WASD walk  |  Shift sprint  |  Drag look")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))

                    DestinationSelectorView(
                        selectedScene: selection.scene,
                        onSelectScene: selectScene,
                        compact: true
                    )

                    TimeScrubberView(
                        year: selection.clampedYear,
                        onYearChange: updateYear,
                        compact: true
                    )
                }
                .padding(18)
                .frame(width: 360, alignment: .leading)
                .background(hudBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))

                Spacer()
            }

            Spacer()
        }
        .padding(20)
    }

    private var visionStatusPanel: some View {
        VStack {
            HStack {
                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("Immersive portal active")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.65))
                    Text("\(selection.scene.title) • \(selection.formattedYear)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Button("Return to Menu", action: exitGame)
                        .buttonStyle(.borderedProminent)
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Mouse look gesture

    @ViewBuilder
    private var hudBackground: some View {
        #if os(macOS)
        Color.black.opacity(0.65)
        #else
        Rectangle().fill(.ultraThinMaterial)
        #endif
    }
 
    /// Click-and-drag to rotate the camera. Uses location deltas rather than
    /// onContinuousHover so it only fires during an active drag.
    var mouseLookGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard gameState == .playing else {
                    lastDragLocation = nil
                    return
                }
                if let last = lastDragLocation {
                    runtime.player.mouseMove(dx: Float(value.location.x - last.x),
                                             dy: Float(value.location.y - last.y))
                }
                lastDragLocation = value.location
            }
            .onEnded { _ in lastDragLocation = nil }
    }
 
    // MARK: - Tap gesture
 
    var tapEntityGesture: some Gesture {
        TapGesture()
            .targetedToEntity(where: .has(SpinComponent.self))
            .onEnded { gesture in
                try? spinEntity(gesture.entity)
            }
    }
 
    // MARK: - Scene Setup (runs once inside RealityView make closure)
 
    private func setupScene(content: any RealityViewContentProtocol) {
        guard runtime.scene.worldRoot == nil else { return }
 
        // ── World root ────────────────────────────────────────────────────────
        let root = Entity()
        root.name = "worldRoot"
        content.add(root)
        runtime.scene.worldRoot = root
 
        // ── Ground grid ───────────────────────────────────────────────────────
        let grid = makeGridEntity(halfExtent: 100, spacing: 1.0)
        root.addChild(grid)
 
        let destinationRoot = Entity()
        destinationRoot.name = "destinationRoot"
        destinationRoot.position = selection.scene.position
        root.addChild(destinationRoot)
        runtime.scene.destinationRoot = destinationRoot
 
        rebuildWindowScene()
 
        // ── Platform-specific camera / anchoring ──────────────────────────────
        #if os(visionOS)
        // In a visionOS window, the system manages the viewer camera.
        #elseif os(iOS) && !targetEnvironment(simulator)
        // iOS/AR platforms use device tracking as the camera.
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
        camera.position = runtime.player.position
        camera.look(
            at: runtime.player.position + SIMD3<Float>(0, 0, -1),
            from: runtime.player.position,
            relativeTo: nil
        )
        // Camera lives in absolute world space, not under worldRoot.
        content.add(camera)
        runtime.scene.camera = camera
        #endif

        runtime.updateSubscription = content.subscribe(to: SceneEvents.Update.self) { event in
            updateScene(deltaTime: Float(min(event.deltaTime, 0.1)))
        }
    }
 
    // MARK: - Per-Frame Update
 
    private func updateScene(deltaTime dt: Float) {
        guard dt > 0 else { return }

        // Apply camera orientation every frame (even during menu) so the GPU
        // rendering path is warm before the user clicks Start.
        #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
        if let cam = runtime.scene.camera {
            let yawQuat   = simd_quatf(angle: runtime.player.yaw,   axis: [0, 1, 0])
            let pitchQuat = simd_quatf(angle: runtime.player.pitch, axis: [1, 0, 0])
            cam.orientation = yawQuat * pitchQuat
        }
        #endif

        guard gameState == .playing else { return }

        // Step physics (uses player.yaw for direction-relative WASD movement)
        let newPosition = runtime.player.update(deltaTime: dt)
 
        // Apply new position to scene
        #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
        runtime.scene.camera?.position = newPosition
 
        #elseif (os(iOS) && !targetEnvironment(simulator)) || os(visionOS)
        let displacement = newPosition - SIMD3<Float>(0, runtime.player.eyeHeight, 0)
        runtime.scene.worldRoot?.position = SIMD3<Float>(-displacement.x, 0, -displacement.z)
        #endif
    }

    private func rebuildWindowScene() {
        guard let destinationRoot = runtime.scene.destinationRoot else { return }

        let activeSelection = selection

        runtime.sceneLoadTask?.cancel()
        runtime.sceneLoadTask = Task { @MainActor in
            for child in Array(destinationRoot.children) {
                child.removeFromParent()
            }

            runtime.player.clearInput()
            runtime.player.resetToGround()

            if let featuredAsset = activeSelection.scene.featuredAsset {
                do {
                    let entity = try await loadSceneAsset(featuredAsset, immersive: false)
                    guard !Task.isCancelled else { return }
                    destinationRoot.position = .zero
                    destinationRoot.addChild(entity)
                    return
                } catch is CancellationError {
                    return
                } catch {
                    print("[ContentView] Failed to load featured asset for '\(activeSelection.scene.title)': \(error)")
                }
            }

            let placeholder = PlaceholderSceneBuilder.makeScene(for: activeSelection, interactive: true)
            destinationRoot.position = activeSelection.scene.position
            destinationRoot.addChild(placeholder)
        }
    }

    private func loadSceneAsset(
        _ configuration: SceneAssetConfiguration,
        immersive: Bool
    ) async throws -> Entity {
        guard let assetURL = Bundle.main.url(
            forResource: configuration.fileStem,
            withExtension: configuration.fileExtension
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let entity = try await Entity(contentsOf: assetURL)
        let anchor = immersive ? configuration.immersivePosition : configuration.windowPosition
        let scale = configuration.scale

        entity.scale = SIMD3<Float>(repeating: scale)
        let bounds = entity.visualBounds(relativeTo: nil)
        entity.position = anchor + SIMD3<Float>(-bounds.center.x, -bounds.min.y, -bounds.center.z)
        return entity
    }

    #if os(macOS) || (os(iOS) && targetEnvironment(simulator))
    private func loadSkyboxResource() -> EnvironmentResource? {
        if let cached = runtime.skyboxResource {
            return cached
        }

        do {
            let resource = try runtime.envManager.loadEnvironmentResource(name: "clarens_midday_4k")
            runtime.skyboxResource = resource
            return resource
        } catch {
            print("[ContentView] Failed to load skybox: \(error)")
            return nil
        }
    }
    #endif

    #if os(macOS)
    private func startKeyboardMonitoring() {
        guard runtime.keyDownMonitor == nil, runtime.keyUpMonitor == nil else { return }

        runtime.keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard gameState == .playing else { return event }
            return handleMacKeyEvent(event, isDown: true) ? nil : event
        }

        runtime.keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyUp) { event in
            return handleMacKeyEvent(event, isDown: false) ? nil : event
        }
    }

    private func stopKeyboardMonitoring() {
        if let monitor = runtime.keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            runtime.keyDownMonitor = nil
        }

        if let monitor = runtime.keyUpMonitor {
            NSEvent.removeMonitor(monitor)
            runtime.keyUpMonitor = nil
        }
    }

    private func handleMacKeyEvent(_ event: NSEvent, isDown: Bool) -> Bool {
        let key: Character?

        switch event.keyCode {
        case 56, 60:
            runtime.player.setSprinting(isDown)
            return true
        case 49:
            key = " "
        default:
            key = event.charactersIgnoringModifiers?.lowercased().first
        }

        guard let key, ["w", "a", "s", "d", " "].contains(key) else {
            return false
        }

        if isDown {
            runtime.player.keyDown(key)
        } else {
            runtime.player.keyUp(key)
        }

        return true
    }
    #endif
 
    // MARK: - Spin helper
 
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

    private func startGame() {
        #if os(visionOS)
        Task { @MainActor in
            guard !immersiveSpaceIsOpen else {
                gameState = .playing
                return
            }

            switch await openImmersiveSpace(id: Self.immersiveSpaceID, value: selection) {
            case .opened:
                gameState = .playing
                immersiveSpaceIsOpen = true
            case .error, .userCancelled:
                gameState = .menu
            @unknown default:
                gameState = .menu
            }
        }
        #else
        rebuildWindowScene()
        lastDragLocation = nil
        runtime.player.resetToGround()
        runtime.player.clearInput()
        gameState = .playing
        #endif
    }

    private func exitGame() {
        #if os(visionOS)
        Task { @MainActor in
            guard immersiveSpaceIsOpen else {
                gameState = .menu
                return
            }

            await dismissImmersiveSpace()
            immersiveSpaceIsOpen = false
            gameState = .menu
        }
        #else
        gameState = .menu
        #endif
    }

    private func selectScene(_ scene: MenuScene) {
        selection.scene = scene
    }

    private func updateYear(_ year: Int) {
        selection.year = min(max(year, TimeTravelSelection.minYear), TimeTravelSelection.maxYear)
    }
}
 
#Preview {
    ContentView()
}
