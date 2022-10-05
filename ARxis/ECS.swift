//
//  ECS.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 05/10/2022.
//

import Foundation
import RealityKit

class ARXisSystem: System {
    required init(scene: Scene) {}

    private static let query = EntityQuery(where: .has(IsCone.self))

    func update(context: SceneUpdateContext) {
        context.scene.performQuery(Self.query).forEach { x in
            debugPrint(x)
        }
    }


}
