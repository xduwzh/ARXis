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

        let fov = createFOV(height: 0.4, fov: camera.defaultFOV, culling: .none)
        let coneAnchor = Entity()

        coneAnchor.addChild(fov)
        anchor.addChild(object)
        object.addChild(coneAnchor)

        arView.installGestures(.translation, for: object)

        arView.scene.anchors.append(anchor)
        cameras.append(CameraInScene(anchor: anchor, model: camera, fov: fov))
    }

    func createFOV(height: Float, fov: (v: Float, h: Float), culling: CustomMaterial.FaceCulling, materials: [Material]? = nil) -> FOVEntity {
        if let materials = materials {
            return FOVEntity(height: height, fov: fov, materials: materials, sceneManager: self)
        }

        let material = SimpleMaterial(color: .random(alpha: 0.6), isMetallic: false)

        var custom1 = try! CustomMaterial(
                from: material,
                geometryModifier: .init(named: "emptyGeometryModifier", in: library)
        )
        custom1.faceCulling = culling
        custom1.baseColor = .init(tint: material.color.tint)

        return FOVEntity(height: height, fov: fov, materials: [custom1], sceneManager: self)
    }

    func setFovHeight(of camera: CameraInScene, to height: Float) {
        let index = cameras.index(of: camera)
        cameras[index].replaceFov(createFOV(height: height, fov: camera.fov.fov, culling: .none, materials: camera.fov.model?.materials))
    }

    func getCamera(at point: CGPoint) -> CameraInScene? {
        let res = arView.hitTest(point)
        if let first = res.first {
            let id = first.entity.anchor?.id
            return cameras.first {
                $0.anchor.id == id
            }
        }
        return nil
    }

    func removeCamera(_ camera: CameraInScene) {
        camera.anchor.removeFromParent()
        cameras.removeAll {
            $0.id == camera.id
        }
    }

    func setSeesIpad(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id) else {
            return
        }

        let ipadEntity = Entity()

        let p = arView.cameraTransform.matrix.columns.3
        ipadEntity.move(to: Transform(translation: [p.x, p.y, p.z]), relativeTo: nil)

        let relativeIpadPos = ipadEntity.position(relativeTo: entity)

        let x = relativeIpadPos.y * tan(entity.fov.v.toRadians / 2)
        let z = relativeIpadPos.y * tan(entity.fov.h.toRadians / 2)

        let seesIpad = x > abs(relativeIpadPos.x) && z > abs(relativeIpadPos.z)
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
        lensesPositions[fov.id] = arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
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
