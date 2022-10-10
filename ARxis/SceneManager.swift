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
    @Published var conePositions: [UInt64?: CGPoint] = [:]
    
    
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
        cameras.append(CameraInScene(anchor: anchor, cameraModelName: camera.name, cone: cone))
    }

    func createCone(radius: Float, height: Float) -> ConeEntity {
        let material = SimpleMaterial(color: .random(alpha: 0.7), isMetallic: false)

        var custom = try! CustomMaterial(
            from: material,
            geometryModifier: .init(named: "emptyGeometryModifier", in: library)
        )

        custom.faceCulling = .none
        custom.baseColor = .init(tint: material.color.tint)

        return ConeEntity(
            radius: radius, height: height, materials: [custom], sceneManager: self
        )
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

    func setSeesIpad(for entity: ConeEntity) {
        guard let camera = getCamera(for: entity.anchor!.id) else { return }

        let anchorPos = camera.cameraEntity.position(relativeTo: nil)
        let ipadPos = arView.cameraTransform.matrix.columns.3
        let conePos = entity.position(relativeTo: nil)

        let index = cameras.index(of: camera)

        let result = arView.scene.raycast(from: SIMD3(ipadPos.x, ipadPos.y, ipadPos.z), to: anchorPos, query: .nearest)
        if let hit = result.first, let anch = hit.entity.anchor {
            debugPrint(Date(), anch.id)
            if anch.id != camera.anchor.id {
                cameras[index].seesIpad = false
                return
            }
        } else {
            cameras[index].seesIpad = false
            return
        }

        let anchorToCamera = normalize(SIMD3(ipadPos.x - anchorPos.x, ipadPos.y - anchorPos.y, ipadPos.z - anchorPos.z))
        let anchorToCone = normalize(SIMD3(conePos.x - anchorPos.x, conePos.y - anchorPos.y, conePos.z - anchorPos.z))

        let angle = acos(dot(anchorToCamera, anchorToCone))

        cameras[index].seesIpad = angle < entity.fovAngle
    }
    
    func setConePosition(for cone: ConeEntity) {
        if let anchor = cone.anchor {
            let pos = arView.project(anchor.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
            conePositions[cone.id] = pos
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
