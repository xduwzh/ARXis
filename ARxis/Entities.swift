//
//  Entities.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

struct IsCone: Component, Codable {}

class ConeEntity: Entity, HasModel {
    required init() {}
    
    init(mesh: MeshResource, materials: [Material]) {
        super.init()
        self.model = ModelComponent(mesh: mesh, materials: materials)
        self.components[IsCone.self] = IsCone()
    }
}
