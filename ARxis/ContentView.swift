//
//  ContentView.swift
//  axisProject
//
//  Created by Aleksy Krolczyk on 13/09/2022.
//

import ARKit
import RealityKit
import SwiftUI

extension ARView: ObservableObject {}

struct ContentView: View {
    @ObservedObject var sceneManager: SceneManager
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: Camera?

    var cameraPos: CGPoint {
        if let entity = selectedCamera?.entity {
            return arView.project(entity.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
        }
        return CGPoint(x: -1, y: -1)
    }

    var body: some View {
        HStack {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geometry in
                    ARViewContainer()
                        .edgesIgnoringSafeArea(.all)
                        .onDrop(of: [.utf8PlainText], isTargeted: nil) { providers, location in
                            providers.loadFirstObject(ofType: String.self) { cameraID in
                                let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                                if let hit = result.first, let camera = CAMERAS.first(where: { $0.id == cameraID }) {
                                    sceneManager.placeCamera(camera, transform: hit.worldTransform)
                                }
                            }
                        }
                        .onTap { point in
                            selectedCamera = sceneManager.getCamera(at: point)
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
                                ObjectManipulator(
                                    onArrowUp: { camera.rotate(angle: .pi/13, axis: .vertical) },
                                    onArrowLeft: { camera.rotate(angle: -.pi/13, axis: .horizontal) },
                                    onArrowRight: { camera.rotate(angle: .pi/13, axis: .horizontal) },
                                    onArrowDown: { camera.rotate(angle: -.pi/13, axis: .vertical) },
                                    onTrashClick: {
                                        sceneManager.removeCamera(camera)
                                        selectedCamera = nil
                                    }
                                )
                                
                            }
                }
                CameraList(cameras: sceneManager.cameras).padding()
            }
            CameraPicker()
        }
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
        config.sceneReconstruction = .mesh
        config.planeDetection = [.vertical, .horizontal]
        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
