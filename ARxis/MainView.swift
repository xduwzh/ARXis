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

struct MainView: View {
    @ObservedObject var sceneManager: SceneManager
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: CameraInScene?

//    var cameraPos: CGPoint {
//        if let entity = selectedCamera?.cameraEntity {
//            return arView.project(entity.position(relativeTo: nil)) ?? CGPoint(x: -1, y: -1)
//        }
//        return CGPoint(x: -1, y: -1)
//    }

    var body: some View {
        HStack {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { _ in
                    ZStack {
                        ARViewContainer()
                            .edgesIgnoringSafeArea(.all)
                            .onDrop(of: [.utf8PlainText], isTargeted: nil) { providers, location in
                                providers.loadFirstObject(ofType: String.self) { cameraID in
                                    let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
                                    if let hit = result.first, let camera = CAMERAS.first(where: { $0.id == cameraID }) {
                                        withAnimation(.linear(duration: 0.3)) {
                                            sceneManager.placeCamera(camera, transform: hit.worldTransform)
                                        }
                                    }
                                }
                            }
                            .onTap { point in
                                selectedCamera = sceneManager.getCamera(at: point)
                            }
                        if selectedCamera != nil {
                            ObjectManipulator(
                                onArrowUp: { selectedCamera!.rotate(angle: -.pi / 13, axis: .vertical) },
                                onArrowLeft: { selectedCamera!.rotate(angle: .pi / 13, axis: .horizontal) },
                                onArrowRight: { selectedCamera!.rotate(angle: -.pi / 13, axis: .horizontal) },
                                onArrowDown: { selectedCamera!.rotate(angle: .pi / 13, axis: .vertical) },
                                onTrashClick: {
                                    sceneManager.removeCamera(selectedCamera!)
                                    selectedCamera = nil

                                },
                                onConeClick: { sceneManager.toggleCone(for: selectedCamera!) },
                                coneActive: selectedCamera!.coneActive
                            )
                            .position(
                                CGPoint(
                                    x: sceneManager.lensesPositions[selectedCamera!.fov.id]?.x ?? 0,
                                    y: (sceneManager.lensesPositions[selectedCamera!.fov.id]?.y ?? 0) + 100
                                )
                            )
                            .clipped()
                        }
                    }
                }
                CameraList(cameras: sceneManager.cameras) { camera in
                    selectedCamera = camera
                }
                .padding()
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
