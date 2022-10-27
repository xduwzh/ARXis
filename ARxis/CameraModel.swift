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

    let rotatablePart: String
    
    var defaultFOV: FOV_T {
        (v: spec.vFOV.upperBound, h: spec.hFOV.upperBound)
    }

    fileprivate init(name: String, rotatablePart: String, spec: TechnicalSpec, scale: SIMD3<Float>? = nil, orientation: simd_quatf? = nil) {
        self.name = name
        self.spec = spec

        let entity = try! Entity.load(named: "\(name)")
        if let scale = scale {
            entity.setScale(scale, relativeTo: nil)
        }
        if let orientation = orientation {
            entity.orientation = orientation
        }
        
        entity.generateCollisionShapes(recursive: true)
        model = ModelEntity()
        model.addChild(entity)

        image = UIImage(named: "CameraModels/\(name).png") ?? UIImage(systemName: "chevron.up")!
    }

//    fileprivate init(name: String, model: ModelEntity, spec: TechnicalSpec) {
//        self.name = name
//        self.model = model
//        self.spec = spec
//        image = UIImage(named: "CameraModels/\(name).png")!
//    }

    func getNew() -> ModelEntity {
        model.clone(recursive: true)
    }
}

let CAMERAS: [CameraModel] = [
    CameraModel(
            name: "AXIS-M4216_LV",
            spec: TechnicalSpec(
                    resolution: (2304, 1728),
                    vFOV: 45...100,
                    hFOV: 34...72
            ),
            scale: SIMD3(repeating: 0.01),
            orientation: simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
    ),
    CameraModel(
            name: "AXIS_P1375-E", // TODO: 123 at the end of name
            spec: TechnicalSpec(
                    resolution: (1920, 1080),
                    vFOV: 42...107,
                    hFOV: 24...57
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
