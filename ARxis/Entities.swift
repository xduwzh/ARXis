//
//  Entities.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

struct IsCone: Component {
    let sceneManager: SceneManager
}

class ConeEntity: Entity, HasModel {
    required init() {}
    var sceneManager: SceneManager {
        self.components[IsCone.self]!.sceneManager
    }
    
    var radius: Float = -1
    var height: Float = -1
    
    var fovAngle: Float {
        atan(radius/height)
    }
    
    init(radius: Float, height: Float, materials: [Material], sceneManager: SceneManager) {
        super.init()
        
        
        let mesh = try! MeshResource.generateCone(radius: radius, height: height, sides: 64, smoothNormals: true)
            
        self.model = ModelComponent(mesh: mesh, materials: materials)
        self.components[IsCone.self] = IsCone(sceneManager: sceneManager)
        
        self.radius = radius
        self.height = height
        
    }
}
