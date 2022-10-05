//
//  Camera.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import Foundation
import RealityKit
import SwiftUI

struct Camera: Identifiable {
    var id: ObjectIdentifier {
        entity.id
    }

    let entity: AnchorEntity
    let cameraModel: String
    var movablePart: Entity {
        return entity.children[0].children[entity.children[0].children.endIndex - 1]
    }

    func enableFOVCone() {
    }
    
    
    enum Axis {
        case horizontal, vertical
        
        var simd: SIMD3<Float> {
            switch self {
                case .horizontal:
                    return [0, 0, 1]
                case .vertical:
                    return [1, 0, 0]
            }
        }
        
    }
    
    func rotate(angle: Float, axis: Axis) {
        movablePart.transform.rotation *= simd_quatf(angle: angle, axis: axis.simd)
    }
    
    
}

struct CameraModel: Identifiable {
    var id: String { name }

    let name: String
    let model: ModelEntity
    let image: UIImage
    
    

    fileprivate init(name: String) {
        self.name = name
        let entity = try! Entity.load(named: "\(name)")
        entity.setScale(SIMD3(repeating: 0.01), relativeTo: nil)
        entity.orientation = simd_quatf(angle: -.pi/2, axis: [1, 0, 0])
        entity.generateCollisionShapes(recursive: true)
        self.model = ModelEntity()
        self.model.addChild(entity)
        self.image = UIImage(named: "CameraModels/\(name).png")!
    }

    
    fileprivate init(name: String, model: ModelEntity) {
        self.name = name
        self.model = model
        self.image = UIImage(named: "CameraModels/\(name).png")!
    }
    
    func getNew() -> ModelEntity {
        return model.clone(recursive: true)
    }

}

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


let CAMERAS: [CameraModel] = [
    CameraModel(name: "AXIS-M4216_LV"),
    CameraModel(name: "AXIS_P1375-E", model: createBox(size: 0.2)),
]
