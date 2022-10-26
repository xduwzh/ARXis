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

    init(arView: ARView) {
        self.arView = arView
    }

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

    func getCamera(for id: UInt64) -> CameraInScene? {
        cameras.first(where: { $0.anchor.id == id })
    }

    func setSeesIpad(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id) else {
            return
        }

        let ipadEntity = arView.getSelfEntity()
        let relativeIpadPos = ipadEntity.position(relativeTo: entity)

        let x = relativeIpadPos.y * tan(entity.fov.v.toRadians / 2)
        let z = relativeIpadPos.y * tan(entity.fov.h.toRadians / 2)

        let seesIpad = x > abs(relativeIpadPos.x) && z > abs(relativeIpadPos.z)
        cameras[cameras.index(of: camera)].seesIpad = seesIpad

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

    func setPixelDensity(for entity: FOVEntity) {
        // We calculate pixel density based on the camera's (currently set) horizontal field of view (angle), the
        // sensor's horizontal pixel count and the distance to the target. Pixel density at the target = sensor's
        // horizontal pixel count / (( horizontal field of view / 180 ) * Pi * the distance to the target ).
        guard let camera = getCamera(for: entity.anchor!.id) else {
            return
        }

        let ipadEntity = arView.getSelfEntity()
        let dist = ipadEntity.position(relativeTo: entity).length
        let spec = camera.model.spec

        cameras[cameras.index(of: camera)].pixelDensity = Double(spec.resolution.0) / Double(camera.fov.fov.h.toRadians * dist)
    }

    func setLensPosition(for fov: FOVEntity) {
        lensesPositions[fov.id] = arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
    }


    func toggleCone(for camera: CameraInScene) {
        let index = cameras.index(of: camera)
        cameras[index].toggleFOVCone()
    }
}

extension Array where Element == CameraInScene {
    func index(of camera: CameraInScene) -> Int {
        firstIndex(where: { $0.id == camera.id })!
    }
}


extension ARView {
    func getSelfEntity() -> Entity {
        let entity = Entity()
        let p = cameraTransform.matrix.columns.3
        entity.move(to: Transform(translation: [p.x, p.y, p.z]), relativeTo: nil)
        return entity
    }
}