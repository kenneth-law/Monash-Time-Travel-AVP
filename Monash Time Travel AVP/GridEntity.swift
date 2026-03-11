//
//  GridEntity.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import RealityKit
import CoreGraphics
import AppKit

/// Creates a ground-plane grid entity centred at the world origin (y = 0).
///
/// Each grid line is a thin flat quad (two triangles) rendered with an
/// `UnlitMaterial` so the lines stay bright regardless of scene lighting.
///
/// - Parameters:
///   - halfExtent:    Half the width/depth of the grid in metres.
///                    Default 100 → 200 × 200 m grid, which appears infinite at eye level.
///   - spacing:       Cell size in metres (default 1.0).
///   - lineHalfWidth: Half the visual width of each grid line in metres (default 0.008).
/// - Returns: An `Entity` with a `ModelComponent` rendering the grid.
func makeGridEntity(
    halfExtent: Float = 100,
    spacing: Float = 1.0,
    lineHalfWidth: Float = 0.008
) -> Entity {

    var positions: [SIMD3<Float>] = []
    var normals:   [SIMD3<Float>] = []
    var indices:   [UInt32] = []
    var idx: UInt32 = 0

    let up = SIMD3<Float>(0, 1, 0)

    /// Appends a thin axis-aligned quad (two triangles) representing one grid line.
    /// `from` and `to` are the endpoints of the line's centreline.
    /// `perp` is the direction perpendicular to the line (on the XZ plane) used
    /// to give the quad its width.
    func addLine(from p0: SIMD3<Float>, to p1: SIMD3<Float>, perp: SIMD3<Float>) {
        let offset = perp * lineHalfWidth
        // Four corners of the quad
        positions.append(contentsOf: [
            p0 - offset,   // 0: near-left
            p0 + offset,   // 1: near-right
            p1 + offset,   // 2: far-right
            p1 - offset    // 3: far-left
        ])
        normals.append(contentsOf: [up, up, up, up])
        // Two CCW triangles: (0,1,2) and (0,2,3)
        indices.append(contentsOf: [idx, idx+1, idx+2, idx, idx+2, idx+3])
        idx += 4
    }

    // Lines parallel to the X axis (constant Z)
    var z = -halfExtent
    while z <= halfExtent + 0.001 {
        addLine(
            from: SIMD3<Float>(-halfExtent, 0, z),
            to:   SIMD3<Float>( halfExtent, 0, z),
            perp: SIMD3<Float>(0, 0, 1)
        )
        z += spacing
    }

    // Lines parallel to the Z axis (constant X)
    var x = -halfExtent
    while x <= halfExtent + 0.001 {
        addLine(
            from: SIMD3<Float>(x, 0, -halfExtent),
            to:   SIMD3<Float>(x, 0,  halfExtent),
            perp: SIMD3<Float>(1, 0, 0)
        )
        x += spacing
    }

    var desc = MeshDescriptor(name: "groundGrid")
    desc.positions = MeshBuffer(positions)
    desc.normals   = MeshBuffer(normals)
    desc.primitives = .triangles(indices)

    // try! is safe: descriptor is built from known-valid data
    let mesh = try! MeshResource.generate(from: [desc])

    var material = UnlitMaterial()
    #if os(macOS)
    material.color = UnlitMaterial.BaseColor(tint: NSColor(white: 0.75, alpha: 1.0))
    #else
    material.color = UnlitMaterial.BaseColor(tint: UIColor(white: 0.75, alpha: 1.0))
    #endif

    let entity = Entity()
    entity.name = "groundGrid"
    entity.components.set(ModelComponent(mesh: mesh, materials: [material]))
    entity.position = .zero

    return entity
}
