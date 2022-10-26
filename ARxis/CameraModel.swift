//
//  CameraModel.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 12/10/2022.
//

import Foundation
import RealityKit
import SwiftUI

struct CameraModel: Identifiable {
    var id: String {
        name
    }

    let name: String
    let model: ModelEntity
    let image: UIImage
    let spec: TechnicalSpec

    var defaultFOV: FOV_T {
        (v: spec.vFOV.upperBound, h: spec.hFOV.upperBound)
    }

    fileprivate init(name: String, spec: TechnicalSpec) {
        self.name = name
        self.spec = spec

        let entity = try! Entity.load(named: "\(name)")
//        entity.setScale(SIMD3(repeating: 0.01), relativeTo: nil)
//        entity.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
//        entity.look(at: [1, 0, 0], from: [0, 0, 0], upVector: [0, 0, 1], relativeTo: entity)
        entity.generateCollisionShapes(recursive: true)
        model = ModelEntity()
        model.addChild(entity)

        image = UIImage(named: "CameraModels/\(name).png") ?? UIImage(systemName: "chevron.up")!
    }

    fileprivate init(name: String, model: ModelEntity, spec: TechnicalSpec) {
        self.name = name
        self.model = model
        self.spec = spec
        image = UIImage(named: "CameraModels/\(name).png")!
    }

    func getNew() -> ModelEntity {
        model.clone(recursive: true)
    }
}

let CAMERAS: [CameraModel] = [
    CameraModel(
            name: "AXIS-M4216_LV",
            spec: TechnicalSpec(
                    resolution: (2304, 1728),
                    vFOV: 34...72,
                    hFOV: 45...100
            )
    ),
    CameraModel(
            name: "AXIS_P1375-E123", // TODO: 123 at the end of name
            spec: TechnicalSpec(
                    resolution: (1920, 1080),
                    vFOV: 24...57,
                    hFOV: 42...107
            )
    ),
]

func createBox(size: Float) -> ModelEntity {
    let box = MeshResource.generateBox(size: size)
    let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
    let boxEntity = ModelEntity(mesh: box, materials: [material])
    boxEntity.generateCollisionShapes(recursive: true)
    return boxEntity
}

func createSphere(radius: Float) -> ModelEntity {
    let sphere = MeshResource.generateSphere(radius: radius)
    let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)

    let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
    sphereEntity.generateCollisionShapes(recursive: true)

    return sphereEntity
}
