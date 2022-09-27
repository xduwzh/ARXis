//
//  ContentView.swift
//  axisProject
//
//  Created by Aleksy Krolczyk on 13/09/2022.
//

import SwiftUI
import RealityKit
import ARKit

extension ARView: ObservableObject {}

struct ContentView : View {
    
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: Camera?
    private let device = MTLCreateSystemDefaultDevice()!
    private var library: MTLLibrary {
        return device.makeDefaultLibrary()!
    }
    
    
    var cameraPos: CGPoint {
        if let entity = selectedCamera?.entity {
            return arView.project(entity.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
        }
        return CGPoint(x: -1, y: -1)
    }
    
    var body: some View {
        HStack {
            GeometryReader { geometry in
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
                    .onDrop(of: [.utf8PlainText], isTargeted: nil) { providers, location in
                        providers.loadFirstObject(ofType: String.self) { cameraID in
                            let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                            if let hit = result.first {
                                var object: ModelEntity? = nil
                                if cameraID == "1" {
                                    object = createSphere(radius: 0.05)
                                }
                                if cameraID == "2" {
                                    object = createBox(size: 0.05)
                                }
                                if let object = object {
                                    placeObject(object, transform: hit.worldTransform)
                                }
                            }
                        }
                    }
                    .onTap { point in
                        let res = arView.hitTest(point)
                        if let first = res.first {
                            selectedCamera = Camera(entity: first.entity)
                            
                        }
                    }
                    .popover(
                        item: $selectedCamera,
                        attachmentAnchor: .point(
                            UnitPoint(
                                x: cameraPos.x / geometry.size.width,
                                y: cameraPos.y / geometry.size.height
                            )
                        ),
                        arrowEdge: .trailing) { camera in
                        ObjectManipulator(camera: camera)
                    }
            }


            CameraPicker()
        }
    }
    
    
    func createSphere(radius: Float) -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        sphereEntity.generateCollisionShapes(recursive: true)
        
        return sphereEntity
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
    
    
    func createBox(size: Float) -> ModelEntity {
        let box = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [material])
        boxEntity.generateCollisionShapes(recursive: true)
        return boxEntity
    }
    
    func placeObject(_ object: ModelEntity, transform: simd_float4x4) {
        let anchor = AnchorEntity(world: transform)
        let cone = createCone(radius: 1, height: 2)
        cone.transform.matrix.columns.3.y = 1
        cone.orientation = simd_quatf(angle: .pi, axis: [0, 0, 1])
        
        anchor.addChild(object)
        object.addChild(cone)
        
        arView.installGestures(.translation, for: object)
        
        arView.scene.anchors.append(anchor)
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    
    @EnvironmentObject private var arView: ARView
    
    func makeUIView(context: Context) -> ARView {        
        arView.automaticallyConfigureSession = false
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.renderOptions = .disableGroundingShadows
        
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.planeDetection = [.vertical, .horizontal]
        arView.session.run(config)
                        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}


//#if DEBUG
//struct ContentView_Previews : PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//#endif

