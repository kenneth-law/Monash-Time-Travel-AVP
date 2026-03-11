//
//  PlayerController.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import SwiftUI
import RealityKit
import Observation

/// Tracks keyboard input and owns player physics state.
/// The RealityView update closure reads this each frame to drive
/// camera/world position — this class contains no RealityKit entity references.
@Observable
final class PlayerController {

    // MARK: - Key tracking

    /// Characters of keys currently held down (e.g. "w", "a", "s", "d", " ").
    var pressedKeys: Set<Character> = []

    // MARK: - Physics state

    /// World-space position; y is always at eye height when on the ground.
    var position: SIMD3<Float> = [0, 1.75, 0]

    /// Velocity in metres per second (world space).
    var velocity: SIMD3<Float> = .zero

    /// True while the player is airborne.
    var isAirborne: Bool = false

    // MARK: - Camera yaw

    /// Horizontal rotation angle in radians, updated from the camera entity
    /// transform each frame so that W always means "forward relative to look".
    var yaw: Float = 0.0

    // MARK: - Delta-time tracking

    /// Timestamp of the previous frame, used to compute dt.
    var lastUpdateTime: Date = Date()

    // MARK: - Tuning constants

    let walkSpeed: Float   = 3.0   // m/s horizontal
    let jumpImpulse: Float = 4.5   // m/s upward at jump onset
    let gravity: Float     = -9.8  // m/s² downward
    let eyeHeight: Float   = 1.75  // metres above floor
    let floorY: Float      = 0.0   // world-space floor plane

    // MARK: - Key event handlers (called from .onKeyPress modifiers)

    func keyDown(_ char: Character) {
        pressedKeys.insert(char.lowercased().first ?? char)
    }

    func keyUp(_ char: Character) {
        pressedKeys.remove(char.lowercased().first ?? char)
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

        velocity.x = worldMove.x * walkSpeed
        velocity.z = worldMove.z * walkSpeed

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
