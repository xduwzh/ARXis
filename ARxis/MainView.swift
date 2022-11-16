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

extension CGSize {
    static func * (lhs: CGSize, rhs: Double) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}

func between(x: Double, lower: Double, upper: Double) -> Bool {
    if x > lower && x < upper {
        return true
    }
    return false
}

struct MainView: View {
    @ObservedObject var sceneManager: SceneManager
    @EnvironmentObject private var arView: ARView
    @State private var selectedCamera: CameraInScene?

    @State var isMeshOn: Bool = false

    var body: some View {
        VStack {
            HStack {
                GeometryReader { proxy in
                    ZStack {
                        ARViewContainer()
                            .edgesIgnoringSafeArea(.all)
                            .onTap { point in
                                selectedCamera = sceneManager.getCamera(at: point)
                            }
                    }

                    
                    if let selectedCamera = selectedCamera, !between(x: sceneManager.lensesPositions[selectedCamera.fov.id]!.pos.x, lower: 0, upper: proxy.size.width) || !between(x: sceneManager.lensesPositions[selectedCamera.fov.id]!.pos.y, lower: 0, upper: proxy.size.height) {
                        let vec = getVector(for: selectedCamera, dimensions: proxy.size)
                        let angle = getRotationAngle(for: selectedCamera, dimensions: proxy.size)
                        Image(systemName: "arrow.right")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .rotationEffect(.init(radians: angle))
                            .offset(x: proxy.size.width / 2, y: proxy.size.height / 2)
                            .offset(getVectorOffset(forGamma: angle, forVec: vec, dimensions: proxy.size * 0.7))
                    }
                }

                VStack {
                    Text("Mesh visibility")
                    Toggle("Mesh visibility", isOn: $isMeshOn)
                        .labelsHidden()
                        .onChange(of: isMeshOn) { value in
                            arView.toggleMesh(isOn: !value)
                        }
                    CameraPicker(onCameraTap: self.sceneManager.placeCamera)
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

        let pos = sceneManager.lensesPositions[camera.fov.id]!.pos
        var xx: SIMD2<Double> = SIMD2(x: pos.x, y: pos.y)
        if !sceneManager.lensesPositions[camera.fov.id]!.isInFront {
            xx *= -1
        }
        let vec = (xx - SIMD2(x: w / 2, y: h / 2))
        return normalize(vec)
    }

    func getRotationAngle(for camera: CameraInScene, dimensions: CGSize) -> Double {
        let w = dimensions.width
        let h = dimensions.height

        let pos = sceneManager.lensesPositions[camera.fov.id]!.pos
        var xx: SIMD2<Double> = SIMD2(x: pos.x, y: pos.y)
        if !sceneManager.lensesPositions[camera.fov.id]!.isInFront {
            xx *= -1
        }
        let vec = (xx - SIMD2(x: w / 2, y: h / 2))
        let angle = acos(dot(normalize(vec), SIMD2(x: 1, y: 0)))

        return pos.y > h / 2 ? angle : 2 * .pi - angle
    }

    func getVectorOffset(forGamma gamma: Double, forVec vec: SIMD2<Double>, dimensions: CGSize) -> CGSize {
        // its terrible i know
        let w = dimensions.width
        let h = dimensions.height

        let alpha = atan(h / w)
        let diagOver2 = sqrt(w * w + h * h) / 2

        let finalGamma = gamma < 2 * .pi - alpha ? gamma : gamma - 2 * .pi

        var length = 0.0
        switch finalGamma {
        case alpha ... .pi - alpha:
            length = h / 2 + abs((diagOver2 - h / 2) * (finalGamma - .pi / 2) / (.pi / 2 - alpha))
        case .pi + alpha ... 2 * .pi - alpha:
            length = h / 2 + abs((diagOver2 - h / 2) * (finalGamma - .pi * 3 / 2) / (.pi / 2 - alpha))
        case -alpha ... alpha:
            length = w / 2 + abs((diagOver2 - w / 2) * (finalGamma / alpha))
        case .pi - alpha ... .pi + alpha:
            length = w / 2 + abs((diagOver2 - w / 2) * ((finalGamma - .pi) / alpha))
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
        let focusSquare = FocusEntity(on: self.arView, focus: .classic)
        
        arView.automaticallyConfigureSession = false
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
