//
//  PlayerController.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI
import RealityKit
import Observation

/// Tracks keyboard/mouse input and owns player physics state.
/// The RealityView update closure reads this each frame to drive
/// camera/world position — this class contains no RealityKit entity references.
@Observable
final class PlayerController {

    // MARK: - Key tracking

    /// Characters of keys currently held down (e.g. "w", "a", "s", "d", " ").
    var pressedKeys: Set<Character> = []

    /// True while the sprint modifier is held.
    var isSprinting: Bool = false

    // MARK: - Physics state

    /// World-space position; y is always at eye height when on the ground.
    var position: SIMD3<Float> = [0, 1.75, 0]

    /// Velocity in metres per second (world space).
    var velocity: SIMD3<Float> = .zero

    /// True while the player is airborne.
    var isAirborne: Bool = false

    // MARK: - Camera orientation (input-driven)

    /// Horizontal rotation angle in radians.
    /// Set by mouse input; W always means "forward relative to current yaw".
    var yaw: Float = 0.0

    /// Vertical rotation angle in radians. Clamped to ±89°.
    var pitch: Float = 0.0

    // MARK: - Tuning constants

    let walkSpeed: Float      = 3.0    // m/s horizontal
    let sprintMultiplier: Float = 2.0
    let jumpImpulse: Float    = 4.5    // m/s upward at jump onset
    let gravity: Float        = -9.8   // m/s² downward
    let eyeHeight: Float      = 1.75   // metres above floor
    let floorY: Float         = 0.0    // world-space floor plane
    let mouseSensitivity: Float = 0.003 // radians per pixel

    // MARK: - Key event handlers

    func keyDown(_ char: Character) {
        pressedKeys.insert(char.lowercased().first ?? char)
    }

    func keyUp(_ char: Character) {
        pressedKeys.remove(char.lowercased().first ?? char)
    }

    func clearInput() {
        pressedKeys.removeAll()
        isSprinting = false
    }

    func setSprinting(_ enabled: Bool) {
        isSprinting = enabled
    }

    // MARK: - Mouse look

    /// Updates yaw and pitch from raw mouse delta values (pixels).
    /// Call from `.onContinuousHover` or any mouse-delta source each frame.
    func mouseMove(dx: Float, dy: Float) {
        yaw   -= dx * mouseSensitivity
        pitch  -= dy * mouseSensitivity
        // Clamp pitch to ±89° to prevent gimbal flip
        let limit = Float.pi / 2 - 0.01
        pitch = max(-limit, min(limit, pitch))
    }

    // MARK: - Per-frame physics update

    /// Integrates player physics by `dt` seconds.
    /// - Returns: The new world-space position.
    @discardableResult
    func update(deltaTime dt: Float) -> SIMD3<Float> {

        // --- Horizontal input (normalise diagonals) ---
        var moveInput: SIMD3<Float> = .zero
        if pressedKeys.contains("w") { moveInput.z -= 1 }
        if pressedKeys.contains("s") { moveInput.z += 1 }
        if pressedKeys.contains("a") { moveInput.x -= 1 }
        if pressedKeys.contains("d") { moveInput.x += 1 }

        let inputLength = length(moveInput)
        if inputLength > 0 { moveInput /= inputLength }

        // Rotate local input by current camera yaw so W = camera-forward
        let cosYaw = cos(yaw)
        let sinYaw = sin(yaw)
        let worldMove = SIMD3<Float>(
            moveInput.x * cosYaw + moveInput.z * sinYaw,
            0,
            -moveInput.x * sinYaw + moveInput.z * cosYaw
        )

        let activeWalkSpeed = walkSpeed * (isSprinting ? sprintMultiplier : 1.0)
        velocity.x = worldMove.x * activeWalkSpeed
        velocity.z = worldMove.z * activeWalkSpeed

        // --- Jump ---
        if pressedKeys.contains(" ") && !isAirborne {
            velocity.y = jumpImpulse
            isAirborne = true
        }

        // --- Gravity ---
        if isAirborne {
            velocity.y += gravity * dt
        }

        // --- Integrate position ---
        position += velocity * dt

        // --- Floor collision ---
        if position.y <= floorY + eyeHeight {
            position.y = floorY + eyeHeight
            velocity.y = 0
            isAirborne = false
        }

        return position
    }
}
