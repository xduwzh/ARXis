//
//  Camera.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import Foundation
import RealityKit

struct Camera: Identifiable {
    var id: ObjectIdentifier {
        entity.id
    }
    
    let entity: Entity
    
    func enableFOVCone() {
        
    }
    
}
