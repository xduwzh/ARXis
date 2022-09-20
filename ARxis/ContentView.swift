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
                            }
                            if let object = object {
                                let anchor = AnchorEntity(world: hit.worldTransform)
                                anchor.addChild(object)
                                arView.scene.addAnchor(anchor)
                            }
                        }
                    }
                }
            CameraPicker()
        }
    }
    
    
    func createSphere(radius: Float) -> ModelEntity {
        let sphere = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial(color: .red, roughness: 0.5, isMetallic: true)
        
        let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
        return sphereEntity
    }
    
    func createBox(size: Float) -> ModelEntity {
        let box = MeshResource.generateBox(size: size)
        let material = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: true)
        let sphereEntity = ModelEntity(mesh: box, materials: [material])
        return sphereEntity
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
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
