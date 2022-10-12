//
//  SceneManager.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import ARKit
import Foundation
import RealityKit

fileprivate extension UIColor {
    static func random(alpha: CGFloat) -> UIColor {
        let colors: [UIColor] = [.red, .magenta, .green, .blue, .cyan, .purple, .yellow]
        return colors.randomElement()!.withAlphaComponent(alpha)
    }
}

class SceneManager: ObservableObject {
    let arView: ARView
    private let device = MTLCreateSystemDefaultDevice()!
    private var library: MTLLibrary {
        return device.makeDefaultLibrary()!
    }

    @Published var cameras: [CameraInScene] = []
    @Published var lensesPositions: [UInt64?: CGPoint] = [:]
    
    
    func placeCamera(_ camera: CameraModel, transform: simd_float4x4) {
        let anchor = AnchorEntity(world: transform)
        let object = camera.getNew()
        
        let fov = createFOV(height: 0.4, vFOV: camera.vFOV, hFOV: camera.hFOV, culling: .none)
        let coneAnchor = Entity()

        coneAnchor.addChild(fov)
        anchor.addChild(object)
        object.addChild(coneAnchor)

        arView.installGestures(.translation, for: object)
 
        arView.scene.anchors.append(anchor)
        cameras.append(CameraInScene(anchor: anchor, cameraModelName: camera.name, fov: fov))
    }
    
    func createFOV(height: Float, vFOV: Float, hFOV: Float, culling: CustomMaterial.FaceCulling) -> FOVEntity {
        let material = SimpleMaterial(color: .random(alpha: 0.6), isMetallic: false)
        
        var custom1 = try! CustomMaterial(
            from: material,
            geometryModifier: .init(named: "emptyGeometryModifier", in: library)
        )
        custom1.faceCulling = culling
        custom1.baseColor = .init(tint: material.color.tint)
        
        return FOVEntity(height: height, vFOV: vFOV, hFOV: hFOV, materials: [custom1], sceneManager: self)
    }
    
    func getCamera(at point: CGPoint) -> CameraInScene? {
        let res = arView.hitTest(point)
        if let first = res.first {
            let id = first.entity.anchor?.id
            return cameras.first { $0.anchor.id == id }
        }
        return nil
    }

    func removeCamera(_ camera: CameraInScene) {
        camera.anchor.removeFromParent()
        cameras.removeAll { $0.id == camera.id }
    }

    func setSeesIpad(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id) else { return }
        
        let ipadPos = arView.cameraTransform.matrix.columns.3
        
        let ipadEntity = Entity()
        ipadEntity.move(to: camera.cameraEntity.transform, relativeTo: nil)
        
        let relativeIpadPos = ipadEntity.position(relativeTo: entity)
        
        let x = relativeIpadPos.y * tan(entity.hFOV.toRadians / 2)
        let z = relativeIpadPos.y * tan(entity.vFOV.toRadians / 2)
        
        let seesIpad = x > relativeIpadPos.x && z > relativeIpadPos.z
        let index = cameras.index(of: camera)
        cameras[index].seesIpad = seesIpad
        
//        let result = arView.scene.raycast(from: SIMD3(ipadPos.x, ipadPos.y, ipadPos.z), to: anchorPos, query: .nearest)
//        if let hit = result.first, let anch = hit.entity.anchor {
//            debugPrint(Date(), anch.id)
//            if anch.id != camera.anchor.id {
//                cameras[index].seesIpad = false
//                return
//            }
//        } else {
//            cameras[index].seesIpad = false
//            return
//        }
//
//        let anchorToCamera = normalize(SIMD3(ipadPos.x - anchorPos.x, ipadPos.y - anchorPos.y, ipadPos.z - anchorPos.z))
//        let anchorToCone = normalize(SIMD3(conePos.x - anchorPos.x, conePos.y - anchorPos.y, conePos.z - anchorPos.z))
//
//        let angle = acos(dot(anchorToCamera, anchorToCone))
//
//        cameras[index].seesIpad = false
//        //        cameras[index].seesIpad = angle < entity.fovAngle
    }
    
    func setLensPosition(for fov: FOVEntity) {
        if let anchor = fov.anchor {
            let pos = arView.project(anchor.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
            lensesPositions[fov.id] = pos
        }
    }

    func getCamera(for id: UInt64) -> CameraInScene? {
        cameras.first(where: { $0.anchor.id == id })
    }

    func toggleCone(for camera: CameraInScene) {
        let index = cameras.index(of: camera)
        cameras[index].toggleFOVCone()
    }

    init(arView: ARView) {
        self.arView = arView
    }
}

extension Array where Element == CameraInScene {
    func index(of camera: CameraInScene) -> Int {
        self.firstIndex(where: { $0.id == camera.id })!
    }
}
