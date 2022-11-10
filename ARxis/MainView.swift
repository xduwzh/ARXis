//
//  ContentView.swift
//  axisProject
//
//  Created by Aleksy Krolczyk on 13/09/2022.
//

import ARKit
import RealityKit
import SwiftUI

extension ARView: ObservableObject {
}

struct MainView: View {
    @ObservedObject var sceneManager: SceneManager
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: CameraInScene?

    @State var isMeshOn: Bool = true

    var body: some View {
        VStack {
            HStack {

                GeometryReader { proxy in
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
                    }

                    if let selectedCamera = selectedCamera {
                        let vec = getVector(for: selectedCamera, dimensions: proxy.size)
                        let angle = getRotationAngle(for: selectedCamera, dimensions: proxy.size)
                        Image(systemName: "arrow.right")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .rotationEffect(.init(radians: angle))
                            .offset(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            .offset(getVectorOffset(forGamma: angle, forVec: vec, dimensions: proxy.size))
//                    Image(systemName: "arrow.right")
//                        .frame(width: 50, height: 50)
                    }

                }

                VStack {
                    Text("Mesh visibility")
                    Toggle("Mesh visibility", isOn: $isMeshOn)
                    .labelsHidden()
                    .onChange(of: isMeshOn) { value in
                        arView.toggleMesh(isOn: !value)
                    }
                    CameraPicker()
                }
            }
            .frame(minHeight: 750)

            HStack {
                CameraList(cameras: sceneManager.cameras, selectedCameraId: selectedCamera?.id) { camera in
                    selectedCamera = camera
                }
                .padding()
                if let selectedCamera = selectedCamera {
                    getObjectManipulator(for: selectedCamera)
                }
            }
            .frame(minHeight: 125)
        }
    }

    func getObjectManipulator(for camera: CameraInScene) -> ObjectManipulator {
        ObjectManipulator(
            onArrowUp: { camera.rotate(angle: -.pi / 12, axis: .vertical) },
            onArrowLeft: { camera.rotate(angle: .pi / 12, axis: .horizontal) },
            onArrowRight: { camera.rotate(angle: -.pi / 12, axis: .horizontal) },
            onArrowDown: { camera.rotate(angle: .pi / 12, axis: .vertical) },
            onTrashClick: {
                sceneManager.removeCamera(camera)
                self.selectedCamera = nil
            },
            onConeClick: { sceneManager.toggleCone(for: camera) },
            onSliderValueChanged: { newHeight in sceneManager.setFovHeight(of: camera, to: newHeight) },
            fovActive: camera.coneActive,
            fovHeight: camera.fov.height
        )
    }

    func getVector(for camera: CameraInScene, dimensions: CGSize) -> SIMD2<Double> {
        let w = dimensions.width
        let h = dimensions.height

        let pos = sceneManager.lensesPositions[camera.fov.id]!
        let vec = (SIMD2(x: pos.x, y: pos.y) - SIMD2(x: w / 2, y: h / 2))
        return normalize(vec)
    }

    func getRotationAngle(for camera: CameraInScene, dimensions: CGSize) -> Double {
        let w = dimensions.width
        let h = dimensions.height

        let pos = sceneManager.lensesPositions[camera.fov.id]!
        let vec = (SIMD2(x: pos.x, y: pos.y) - SIMD2(x: w / 2, y: h / 2))
        let angle = acos(dot(normalize(vec), SIMD2(x: 1, y: 0)))

        debugPrint(angle * 180 / .pi)
        return pos.y > h / 2 ? angle : 2 * .pi - angle

    }

    func getVectorOffset(forGamma gamma: Double, forVec vec: SIMD2<Double>, dimensions: CGSize) -> CGSize {
        // its terrible i know
        let w = dimensions.width
        let h = dimensions.height

        let alpha = atan(h / w)
        let diagOver2 = sqrt(w * w + h * h) / 2

        var length = 0.0
        switch gamma {
            case alpha ... .pi - alpha:
            debugPrint(1)
            length = h / 2 + (diagOver2 - h/2) * (gamma - .pi/2) / (.pi/2 - alpha)
            case .pi + alpha ... 2 * .pi - alpha:
            debugPrint(2)
            length = h / 2 + (diagOver2 - h/2) * (gamma - .pi * 3/2) / (.pi/2 - alpha)
            case -alpha ... alpha:
            debugPrint(3)
            length = w/2 + (diagOver2 - w/2) * (gamma / alpha)
            case .pi - alpha ... .pi + alpha:
            debugPrint(4)
            length = w/2 + (diagOver2 - w/2) * ((gamma - .pi) / alpha)
        default:
            length = diagOver2
        }

        let scaled = vec * length

        return CGSize(width: scaled.x, height: scaled.y)

    }
}

struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject private var arView: ARView
    var showsMesh = true


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

extension ARView {
    func toggleMesh(isOn: Bool) {
        if isOn {
            debugOptions.remove(.showSceneUnderstanding)
        } else {
            debugOptions.insert(.showSceneUnderstanding)
        }
    }

}
