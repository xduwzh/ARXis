//
//  SceneManager.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import Foundation
import ARKit
import RealityKit

fileprivate extension UIColor {
    static func random(alpha: CGFloat) -> UIColor {
//        return UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: alpha)
        let colors: [UIColor] = [.red, .magenta, .green, .blue, .cyan, .purple, .yellow]
        return colors.randomElement()!.withAlphaComponent(alpha)
    }
    
}

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
        let coneAnchor = Entity()
        cone.transform.matrix.columns.3.y = 1
        cone.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
        
        coneAnchor.addChild(cone)
        anchor.addChild(object)
        object.addChild(coneAnchor)
        
        arView.installGestures(.translation, for: object)
        
        arView.scene.anchors.append(anchor)
        
        cameras.append(Camera(entity: anchor, cameraModel: camera.name))
    }
    
    func createCone(radius: Float, height: Float) -> Entity {
        let cone = try! MeshResource.generateCone(radius: radius, height: height, sides: 64, smoothNormals: true)
        let material = SimpleMaterial(color: .random(alpha: 0.7), isMetallic: false)
        
        var custom = try! CustomMaterial(
            from: material,
            geometryModifier: .init(named: "emptyGeometryModifier", in: library)
        )
        
        custom.faceCulling = .none
        custom.baseColor = .init(tint: material.color.tint)
        
        let coneEntity = ConeEntity(mesh: cone, materials: [custom])
        
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
