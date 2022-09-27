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

//struct CameraDroppable: ViewModifiers {
//    func body(content: Content) -> some View {
//        return content
//    }
//}
//
//extension View {
//    func onCameraDrop(callback: ((String) -> Void)) {
//
//        return self
//    }
//}

struct ContentView : View {
    
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: Entity?
    
    var body: some View {
        HStack {
            
            ARViewContainer()
                .edgesIgnoringSafeArea(.all)
                .onDrop(of: [.utf8PlainText], isTargeted: nil) { providers, location in
                    providers.loadFirstObject(ofType: String.self) { cameraID in
                        let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                        if let hit = result.first {
                            var object: ModelEntity? = nil
                            if cameraID == "1" {
                                object = createSphere(radius: 0.2)
                            }
                            if cameraID == "2" {
                                object = createBox(size: 0.2)
                                selectedCamera = object
                            }
                            if let object = object {
                                let anchor = AnchorEntity(world: hit.worldTransform)
                                anchor.addChild(object)
                                arView.scene.addAnchor(anchor)
                            }
                        }
                    }
                }
                .onTap { point in
                    debugPrint(point)
                    let res = arView.hitTest(point)
                    if let first = res.first {
                        selectedCamera = first.entity
                    }
                }
                .popover(item: $selectedCamera) { camera in
                    Text("halo")
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
    
    func createBox(size: Float) -> ModelEntity {
        let box = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [material])
        boxEntity.generateCollisionShapes(recursive: true)
        return boxEntity
    }
    
    func placeObject(_ object: ModelEntity, at position: SIMD3<Float>) {
        let anchor = AnchorEntity(world: position)
        anchor.addChild(object)
        arView.scene.anchors.append(anchor)
    }
    
}

struct ARViewContainer: UIViewRepresentable {
    
//    @EnvironmentObject private var sceneManager: SceneManager
    @EnvironmentObject private var arView: ARView
    
//    let arView: ARView = ARView(frame: .zero)
    
    func makeUIView(context: Context) -> ARView {        
        arView.automaticallyConfigureSession = false
        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .meshWithClassification
        config.planeDetection = [.vertical, .horizontal]
        arView.session.run(config)
        
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    class Coordinator: NSObject, ARSessionDelegate {
        dynamic func touchesBegan(
            _ touches: Set<UITouch>,
            with event: UIEvent
        ) {
            debugPrint("DSADASD")
        }
    }
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
