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
    let cameraModelName: String
    let fov: FOVEntity
    var seesIpad: Bool

    var movablePart: Entity
    var cameraEntity: Entity

    init(anchor: AnchorEntity, cameraModelName: String, fov: FOVEntity) {
        self.anchor = anchor
        self.cameraModelName = cameraModelName
        self.fov = fov
        self.seesIpad = false
        
        self.cameraEntity = anchor.children[0]
        self.movablePart = self.cameraEntity.children[self.cameraEntity.children.endIndex - 1]
    }

    var coneActive: Bool {
        fov.isActive
    }

    func toggleFOVCone() {
        movablePart.isEnabled.toggle()
    }

    func rotate(angle: Float, axis: Axis) {
        movablePart.transform.rotation *= simd_quatf(angle: angle, axis: axis.simd)
    }
}
