//
//  EnvironmentManager.swift
//  Monash Time Travel AVP
//
//  Created by Ken Law on 11/3/2026.
//

import RealityKit
import Foundation
import Observation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Manages the lifecycle of dynamically loaded USDZ assets in the scene.
///
/// Call `setRoot(_:)` once from inside the `RealityView` make closure after
/// adding the `environmentRoot` entity to the scene. Then call
/// `loadFromBundle` or `loadFromURL` from async contexts (e.g. button actions
/// or `.task {}` modifiers) to place assets, and `remove(id:)` / `clearAll()`
/// to remove them.
@MainActor
@Observable
final class EnvironmentManager {

    // MARK: - Types

    typealias AssetID = String

    // MARK: - State

    /// The parent entity for all dynamic assets. Set once via `setRoot(_:)`.
    private(set) var environmentRoot: Entity?

    /// Maps asset IDs to their loaded entities for later removal.
    private var loadedAssets: [AssetID: Entity] = [:]

    /// Temporary extracted URLs for USDZ files stored inside asset catalogs.
    private var extractedBundleAssetURLs: [String: URL] = [:]

    // MARK: - Setup

    /// Binds the manager to the environment root entity in the scene.
    /// Must be called from the `RealityView` make closure.
    func setRoot(_ root: Entity) {
        environmentRoot = root
    }

    // MARK: - Loading from app bundle

    /// Loads a USDZ by filename (no extension) from the main app bundle.
    ///
    /// The file must be included in the app target's "Copy Bundle Resources".
    /// With `PBXFileSystemSynchronizedRootGroup`, any `.usdz` dropped into the
    /// `Monash Time Travel AVP/` source folder is included automatically.
    ///
    /// - Parameters:
    ///   - name: Filename without extension (e.g. `"tree"`).
    ///   - id: Unique string identifier; used to remove the asset later.
    ///   - position: World-space position to place the asset.
    ///   - orientation: Quaternion rotation (identity by default).
    ///   - scale: Uniform scale factor (1.0 by default).
    func loadFromBundle(
        name: String,
        id: AssetID,
        position: SIMD3<Float>,
        orientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        scale: Float = 1.0
    ) async throws {
        guard let root = environmentRoot else {
            print("[EnvironmentManager] environmentRoot not set — call setRoot() first.")
            return
        }
        // Remove any pre-existing asset with the same id
        remove(id: id)

        let assetURL = try bundleAssetURL(name: name, fileExtension: "usdz")
        let entity = try await Entity(contentsOf: assetURL)
        place(entity: entity, id: id, position: position,
              orientation: orientation, scale: scale, under: root)
    }

    // MARK: - Loading from URL (local file or remote)

    /// Loads a USDZ from a file URL (can be a local path or remote URL).
    ///
    /// - Parameters:
    ///   - url: Full URL to the `.usdz` file.
    ///   - id: Unique identifier for later removal.
    ///   - position: World-space position.
    ///   - orientation: Quaternion rotation (identity by default).
    ///   - scale: Uniform scale factor (1.0 by default).
    func loadFromURL(
        url: URL,
        id: AssetID,
        position: SIMD3<Float>,
        orientation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0]),
        scale: Float = 1.0
    ) async throws {
        guard let root = environmentRoot else {
            print("[EnvironmentManager] environmentRoot not set — call setRoot() first.")
            return
        }
        remove(id: id)

        let entity = try await Entity(contentsOf: url)
        place(entity: entity, id: id, position: position,
              orientation: orientation, scale: scale, under: root)
    }

    // MARK: - Removal

    /// Removes a previously loaded asset by its identifier.
    func remove(id: AssetID) {
        guard let entity = loadedAssets[id] else { return }
        entity.removeFromParent()
        loadedAssets.removeValue(forKey: id)
    }

    /// Removes all dynamically loaded assets from the scene.
    func clearAll() {
        for entity in loadedAssets.values {
            entity.removeFromParent()
        }
        loadedAssets.removeAll()
    }

    /// Returns the IDs of all currently loaded assets.
    var loadedIDs: [AssetID] { Array(loadedAssets.keys) }

    // MARK: - Private helpers

    private func place(
        entity: Entity,
        id: AssetID,
        position: SIMD3<Float>,
        orientation: simd_quatf,
        scale: Float,
        under root: Entity
    ) {
        entity.name = id
        entity.position = position
        entity.orientation = orientation
        entity.scale = SIMD3<Float>(repeating: scale)
        root.addChild(entity)
        loadedAssets[id] = entity
    }

    func bundleAssetURL(name: String, fileExtension: String) throws -> URL {
        if let url = Bundle.main.url(forResource: name, withExtension: fileExtension) {
            return url
        }

        let cacheKey = "\(name).\(fileExtension)"

        if let cachedURL = extractedBundleAssetURLs[cacheKey] {
            return cachedURL
        }

        guard let dataAsset = NSDataAsset(name: name) else {
            throw CocoaError(.fileNoSuchFile)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Monash-Time-Travel-AVP-\(name)")
            .appendingPathExtension(fileExtension)

        if !FileManager.default.fileExists(atPath: url.path) {
            try dataAsset.data.write(to: url, options: Data.WritingOptions.atomic)
        }

        extractedBundleAssetURLs[cacheKey] = url
        return url
    }
}
