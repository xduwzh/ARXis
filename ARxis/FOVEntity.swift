//
//  Entities.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

struct IsFOV: Component {
    let sceneManager: SceneManager
}

class FOVEntity: Entity, HasModel {
    required init() {}
    var sceneManager: SceneManager {
        self.components[IsFOV.self]!.sceneManager
    }

    var height: Float = -1
    var vFOV: Float = -1
    var hFOV: Float = -1

    init(height: Float, vFOV: Float, hFOV: Float, materials: [Material], sceneManager: SceneManager) {
        super.init()

        let mesh = try! MeshResource.generatePyramid(height: height, horizontalFOV: hFOV, verticalFOV: vFOV)

        self.model = ModelComponent(mesh: mesh, materials: materials)
        self.components[IsFOV.self] = IsFOV(sceneManager: sceneManager)

        self.height = height
        self.vFOV = vFOV
        self.hFOV = hFOV

        self.createEdges()
    }

    private func createEdges() {
        let x = self.height * tan(self.vFOV.toRadians / 2)
        let z = self.height * tan(self.hFOV.toRadians / 2)
        
        var edges: [Entity] = []
        let depth = length(SIMD3([x, self.height, z]))
        for _ in 0 ..< 4 {
            edges.append(createBox(depth: depth))
        }

        edges[0].look(
            at: SIMD3([x, self.height, z]).normalised,
            from: SIMD3([x / 2, self.height / 2, z / 2]),
            relativeTo: self
        )
        edges[1].look(
            at: SIMD3([x, self.height, -z]).normalised,
            from: SIMD3([x / 2, self.height / 2, -z / 2]),
            relativeTo: self
        )
        edges[2].look(
            at: SIMD3([-x, self.height, z]).normalised,
            from: SIMD3([-x / 2, self.height / 2, z / 2]),
            relativeTo: self
        )
        edges[3].look(
            at: SIMD3([-x, self.height, -z]).normalised,
            from: SIMD3([-x / 2, self.height / 2, -z / 2]),
            relativeTo: self
        )

        self.children.append(contentsOf: edges)
    }
}

private func createBox(depth: Float) -> ModelEntity {
    let box = MeshResource.generateBox(width: 0.005, height: 0.005, depth: depth)
    let material = UnlitMaterial(color: .black)
    let boxEntity = ModelEntity(mesh: box, materials: [material])
    return boxEntity
}
