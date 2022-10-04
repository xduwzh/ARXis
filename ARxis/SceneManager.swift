//
//  SceneManager.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import Foundation
import ARKit
import RealityKit

class SceneManager: ObservableObject {
    let arView: ARView
    @Published var cameras: [Camera] = []
    private let device = MTLCreateSystemDefaultDevice()!
    private var library: MTLLibrary {
        return device.makeDefaultLibrary()!
    }

    func placeCamera(_ camera: CameraModel, transform: simd_float4x4) {
        let anchor = AnchorEntity(world: transform)
        let cone = createCone(radius: 1, height: 2)
        let object = camera.getNew()
        cone.transform.matrix.columns.3.y = 1
        cone.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
        
        anchor.addChild(object)
        object.addChild(cone)
        
        arView.installGestures(.translation, for: object)
        
        arView.scene.anchors.append(anchor)
        
        cameras.append(Camera(entity: anchor, cameraModel: camera.name))
    }
    
    func createCone(radius: Float, height: Float) -> ModelEntity {
        let cone = try! MeshResource.generateCone(radius: radius, height: height, sides: 32, smoothNormals: true)
        var material = SimpleMaterial(color: .magenta, roughness: 0.5, isMetallic: true)
        material.color.tint = material.color.tint.withAlphaComponent(0.7)
        
        var custom = try! CustomMaterial(from: material, surfaceShader: .init(named: "emptyGeometryModifier", in: library))
        custom.faceCulling = .none
        custom.baseColor = .init(tint: material.color.tint)
        
        let coneEntity = ModelEntity(mesh: cone, materials: [custom])
        
        return coneEntity
    }
    
    func getCamera(at point: CGPoint) -> Camera? {
        let res = arView.hitTest(point)
        if let first = res.first {
            let id = first.entity.anchor?.id
            return cameras.first { $0.entity.id == id }
        }
        return nil
    }
    
    func removeCamera(_ camera: Camera) {
        camera.entity.removeFromParent()
        cameras.removeAll { $0.id == camera.id }
    }
    
    init(arView: ARView) {
        self.arView = arView
    }
}
