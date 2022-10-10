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
        context.scene.performQuery(Self.query).compactMap { $0 as? ConeEntity }.forEach { cone in
            cone.sceneManager.setSeesIpad(for: cone)
            cone.sceneManager.setConePosition(for: cone)
//            context.scene.subscribe(to: <#T##Event.Protocol#>, <#T##handler: (Event) -> Void##(Event) -> Void#>) TODO: zrobic
        }
    }
}
