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
    var id: String { name }
    
    let name: String
    let vFOV: Float
    let hFOV: Float
    let model: ModelEntity
    let image: UIImage
    
    fileprivate init(name: String, vFOV: Float, hFOV: Float) {
        self.name = name
        self.vFOV = vFOV
        self.hFOV = hFOV
        
        let entity = try! Entity.load(named: "\(name)")
//        entity.setScale(SIMD3(repeating: 0.01), relativeTo: nil)
//        entity.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
//        entity.look(at: [1, 0, 0], from: [0, 0, 0], upVector: [0, 0, 1], relativeTo: entity)
        entity.generateCollisionShapes(recursive: true)
        self.model = ModelEntity()
        self.model.addChild(entity)
        self.image = UIImage(named: "CameraModels/\(name).png")!
    }
    
    fileprivate init(name: String, model: ModelEntity, vFOV: Float, hFOV: Float) {
        self.name = name
        self.model = model
        self.vFOV = vFOV
        self.hFOV = hFOV
        self.image = UIImage(named: "CameraModels/\(name).png")!
    }
    
    func getNew() -> ModelEntity {
        let clone = model.clone(recursive: true)
        return clone
    }
}

// AXIS-M4216_LV"
// 100-45 °
// 72-34 °



// AXIS_P1375-E
// 107-42 °
// 57-24 °

let CAMERAS: [CameraModel] = [
    CameraModel(name: "AXIS-M4216_LV", vFOV: 100, hFOV: 72),
    CameraModel(name: "AXIS_P1375-E", vFOV: 107, hFOV: 57),
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
