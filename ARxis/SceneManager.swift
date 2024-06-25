//
//  SceneManager.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import ARKit
import Foundation
import RealityKit
import SwiftUI

fileprivate extension UIColor {
    static func random(alpha: CGFloat) -> UIColor {
        let colors: [UIColor] = [.red, .magenta, .green, .blue, .cyan, .purple, .yellow]
        return colors.randomElement()!.withAlphaComponent(alpha)
    }
}

struct LensPosition {
    let pos: CGPoint
    let isInFront: Bool
}

class SceneManager: ObservableObject {
    let arView: ARView
    let arStatus: ARStatus
    private let device = MTLCreateSystemDefaultDevice()!
    private var library: MTLLibrary {
        device.makeDefaultLibrary()!
    }
    
    @Published var cameras: [CameraInScene] = []
    @Published var lensesPositions: [UInt64?: LensPosition] = [:]
    @Published var showAlert = false
    @Published var loading = false

    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.planeDetection = [.vertical, .horizontal]
        return config
    }
    
    
    
    
    init(arView: ARView, arStatus:ARStatus) {
        self.arView = arView
        self.arStatus = arStatus
    }
    
    func placeCamera(_ camera: CameraModel, transform: simd_float4x4) {
        if cameras.count == 10 {
            //showAlert = true
            return
        }
        let anchorName = camera.name + String(cameras.count)
        let arAnchor = ARAnchor(name: anchorName, transform: transform)
        arView.session.add(anchor: arAnchor)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let anchor = self.arView.scene.anchors.first{ $0.name == anchorName }
            let object = anchor!.children[0]
            let fov = self.createFOV(height: 0.4, fov: camera.defaultFOV, culling: .none)
            //self.createProjection(fovEntity: fov)
            let coneAnchor = Entity()
            coneAnchor.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
            coneAnchor.addChild(fov)
            
            let lensEntity = object.findEntity(named: camera.lensPart)!
            lensEntity.addChild(coneAnchor)
            //print(transform.translation)
            //print(fov.convert(transform: .identity, to: nil).translation)

            self.arView.installGestures(.translation, for: object as! HasCollision)
            self.cameras.append(CameraInScene(anchor: anchor! as! AnchorEntity, model: camera, fov: fov))
        }
        
        
        
    }
    
    func createFOV(height: Float, fov: (v: Float, h: Float), culling: CustomMaterial.FaceCulling, materials: [RealityKit.Material]? = nil) -> FOVEntity {
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
    
    func createProjection(fovEntity: FOVEntity) {
        let pos = fovEntity.convert(transform: .identity, to: nil).translation
        let x = fovEntity.height * tan(fovEntity.fov.v.toRadians / 2)
        let z = fovEntity.height * tan(fovEntity.fov.h.toRadians / 2)
        let c1 = SIMD3([x / 2, fovEntity.height / 2, z / 2]), d1 = SIMD3([x, fovEntity.height, z]).normalised
        let c2 = SIMD3([x / 2, fovEntity.height / 2, -z / 2]), d2 = SIMD3([x, fovEntity.height, -z]).normalised
        let c3 = SIMD3([-x / 2, fovEntity.height / 2, z / 2]), d3 = SIMD3([-x, fovEntity.height, z]).normalised
        let c4 = SIMD3([-x / 2, fovEntity.height / 2, -z / 2]), d4 = SIMD3([-x, fovEntity.height, -z]).normalised
        let centers = [c1,c2,c3,c4], directions = [d1,d2,d3,d4]
        for i in 0...3 {
            let rcQuery = ARRaycastQuery(
                origin: pos + centers[i], direction: directions[i],
                allowing: .estimatedPlane, alignment: .any
            )
            let result = self.arView.session.raycast(rcQuery)
            if let hit = result.first {
                //let camera = CAMERAS.first(where: { $0.id == cameraModelId })
                let virtualObjectAnchor = ARAnchor(
                    name:"AXIS_M4216_LV1",
                    transform: hit.worldTransform
                )
                self.arView.session.add(anchor: virtualObjectAnchor)
                print("Add projection")
            }
        }
        
    }
    
    func setFovHeight(of camera: CameraInScene, to height: Float) {
        let index = cameras.index(of: camera)
        let newHeight = min((1/(-height + 1)) - 1, 100)
        cameras[index].replaceFov(createFOV(height: newHeight, fov: camera.fov.fov, culling: .none, materials: camera.fov.model?.materials))
    }
    
    func setDistanceToFloor(for entity: FOVEntity) {
        guard let camera = getCamera(for: entity.anchor!.id), camera.distanceToFloor != nil else {
            return
        }
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
        
        if !seesIpad {
            return
        }
        
        guard let (camPos, camDir) = self.getCamVector() else {
            return
        }
        let dir = camera.cameraEntity.position(relativeTo: nil) - camPos
        let rcQuery = ARRaycastQuery(
            origin: camPos, direction: dir,
            allowing: .estimatedPlane, alignment: .any
        )
        let result = self.arView.session.raycast(rcQuery)
        if let hit = result.first {
            let pos = hit.worldTransform.columns.3
            let leng = ([pos.x, pos.y, pos.z] - camera.cameraEntity.position(relativeTo: nil)).length
            if leng > 0.09 { // chosen arbitrarily
                cameras[cameras.index(of: camera)].seesIpad = false
            }
        }
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
        
        // TODO: fov.v is really fov.h
        cameras[cameras.index(of: camera)].pixelDensity = (Double(spec.resolution.0) / Double(camera.fov.fov.v.toRadians * dist)) / 5.0
    }
    
    func setLensPosition(for fov: FOVEntity) {
        
        //        let projection = arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
        let relPos = fov.position(relativeTo: arView.getSelfEntity())
        
        let lensPos = LensPosition(
            pos: arView.project(fov.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1),
            isInFront: relPos.z < 0
        )
        
        lensesPositions[fov.id] = lensPos
    }
    
    
    func toggleCone(for camera: CameraInScene) {
        let index = cameras.index(of: camera)
        cameras[index].toggleFOVCone()
    }
    
    func placeCamera(ofType cameraModelId: String) {
        guard let (camPos, camDir) = self.getCamVector() else {
            return
        }
        let rcQuery = ARRaycastQuery(
            origin: camPos, direction: camDir,
            allowing: .estimatedPlane, alignment: .any
        )
        let result = self.arView.session.raycast(rcQuery)
        if let hit = result.first, let camera = CAMERAS.first(where: { $0.id == cameraModelId }) {
            self.placeCamera(camera, transform: hit.worldTransform)
        }
    }
    
    internal func getCamVector() -> (position: SIMD3<Float>, direciton: SIMD3<Float>)? {
        let camTransform = self.arView.cameraTransform
        let camDirection = camTransform.matrix.columns.2
        return (camTransform.translation, -[camDirection.x, camDirection.y, camDirection.z])
    }
    
    // MARK: AR Saving function (Persistence)
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    

    
    func setUpLabelsAndButtons(text: String, canShowSaveButton: Bool) {
        arStatus.infoLabel = text
        arStatus.saveEnabled = canShowSaveButton
    }
    
    func loadMap() {
        loading = true
        cameras.removeAll()
        arView.scene.anchors.removeAll()
        guard let mapData = try? Data(contentsOf: self.worldMapURL), let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) else {
            fatalError("No ARWorldMap in archive.")
        }
        
        let configuration = defaultConfiguration
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        configuration.initialWorldMap = worldMap
        print("Map loaded")
        arView.session.run(configuration, options: options)
        
        loadCones()

    }
    
    func loadCones(){
        if self.arView.scene.anchors.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadCones()
            }
        } else {
            print(self.arView.scene.anchors.isEmpty)
            for anchor in self.arView.scene.anchors {
                let anchorName = anchor.name
                let camera = CAMERAS.first { $0.name == anchorName.dropLast() }
                let anchor = self.arView.scene.anchors.first { $0.name == anchorName }
                let object = anchor!.children[0]
                let fov = self.createFOV(height: 0.4, fov: camera!.defaultFOV, culling: .none)
                let coneAnchor = Entity()
                
                coneAnchor.orientation = simd_quatf(angle: .pi/2, axis: [1, 0, 0])
                coneAnchor.addChild(fov)
                
                let lensEntity = object.findEntity(named: camera!.lensPart)!
                lensEntity.addChild(coneAnchor)
                
                self.arView.installGestures(.translation, for: object as! HasCollision)
                self.cameras.append(CameraInScene(anchor: anchor! as! AnchorEntity, model: camera!, fov: fov))
                self.loading = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let _ = FocusEntity(on: self.arView, focus: .classic)
                
            }
        }
    }
  
    func saveMap() {
        cameras.removeAll()
        // ARAnchor's transform cannot be changed
        // so we have to replace it with a new one which
        // located in the position after user's manipulation
        for anchor in arView.session.currentFrame!.anchors{
            if let anchorName = anchor.name, anchorName.contains("AXIS"){
                let anchorEntity = self.arView.scene.anchors.first{ $0.name == anchorName }
                let object = anchorEntity!.children[0]
                let anchorWorldTransform = object.convert(transform: .identity, to: nil)
                print(anchorWorldTransform.translation)
                print(anchor.transform.translation)
                //let arAnchor = ARAnchor(name: anchorName, transform: anchorWorldTransform.matrix)
                arView.session.remove(anchor: anchor)
                arView.scene.removeAnchor(anchorEntity!)
                let camera = CAMERAS.first(where: { $0.id == anchorName.dropLast() })
                placeCamera(camera!, transform: anchorWorldTransform.matrix)
                
            }
        }
        
        // wait anchor replacement to be finished
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.arView.session.getCurrentWorldMap { (worldMap, error) in
                guard let worldMap = worldMap else {
                    self.setUpLabelsAndButtons(text: "Can't get current world map", canShowSaveButton: false)
                    print(error!.localizedDescription)
                    return
                }
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                    try data.write(to: self.worldMapURL, options: [.atomic])
                    print("Map saved")
                } catch {
                    fatalError("Can't save map: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func resetScene(){
        cameras.removeAll()
        if let _ = arView.session.currentFrame{
            if !arView.session.currentFrame!.anchors.isEmpty{
                for anchor in arView.session.currentFrame!.anchors{
                    arView.session.remove(anchor: anchor)
                }
            }
        }
        arView.scene.anchors.removeAll()
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        //self.debugOptions = [.showFeaturePoints]
        arView.session.run(defaultConfiguration, options: options)
        setUpLabelsAndButtons(text: "Move the camera around to detect surfaces", canShowSaveButton: false)
        let _ = FocusEntity(on: self.arView, focus: .classic)
    }
}

extension Array where Element == CameraInScene {
    func index(of camera: CameraInScene) -> Int {
        firstIndex(where: { $0.id == camera.id })!
    }
}


extension ARView: ARSessionDelegate {
    func getSelfEntity() -> Entity {
        let entity = Entity()
        let p = cameraTransform.matrix.columns.3
        entity.move(to: Transform(translation: [p.x, p.y, p.z]), relativeTo: nil)
        entity.transform.rotation = cameraTransform.rotation
        return entity
    }
    
    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        //print("did add anchor: \(anchors.count) anchors in total")
        
        // ARWolrdMap contains only the ARAnchor data,
        // to restore the models, we need to turn it into AnchorEntity
        // and attach a ModelEntity to it
        for anchor in anchors {
            addAnchorEntityToScene(anchor: anchor)
        }
    }
    
    
    func addAnchorEntityToScene(anchor: ARAnchor) {
        if let name = anchor.name, name.contains("AXIS") {
            let camera = CAMERAS.first { $0.name == name.dropLast() }
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.name = anchor.name!
            //print(anchorEntity.name)
            let object = camera!.getNew()
            anchorEntity.addChild(object)
            self.scene.addAnchor(anchorEntity)
            self.installGestures(for: object)
        }
    }
    
}

