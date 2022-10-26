//
//  Camera.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import Foundation
import RealityKit
import SwiftUI

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

struct CameraInScene: Identifiable {
    var id: ObjectIdentifier {
        anchor.id
    }

    let anchor: AnchorEntity
    let model: CameraModel
    private(set) var fov: FOVEntity
    var seesIpad: Bool

    var movablePart: Entity
    var cameraEntity: Entity

    var coneActive: Bool {
        fov.isActive
    }

    init(anchor: AnchorEntity, model: CameraModel, fov: FOVEntity) {
        self.anchor = anchor
        self.model = model
        self.fov = fov
        seesIpad = false

        cameraEntity = anchor.children[0]
        movablePart = cameraEntity.children[cameraEntity.children.endIndex - 1]
    }

    func toggleFOVCone() {
        movablePart.isEnabled.toggle()
    }

    func rotate(angle: Float, axis: Axis) {
        movablePart.transform.rotation *= simd_quatf(angle: angle, axis: axis.simd)
    }

    mutating func replaceFov(_ newFov: FOVEntity) {
        if let fovParent = fov.parent {
            fov.removeFromParent()
            fovParent.addChild(newFov)
            fov = newFov
        }
    }

}
