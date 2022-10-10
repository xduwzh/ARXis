//
//  CameraList.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 04/10/2022.
//

import SwiftUI

extension CameraInScene {
    func toCameraModel() -> CameraModel {
        CAMERAS.first { cameraModel in
            cameraModel.name == self.cameraModelName
        }!
    }
}

struct CameraList: View {
    let cameras: [CameraInScene]
    var onCameraTap: (CameraInScene) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(cameras) { camera in
                    VStack {
                        Image(uiImage: camera.toCameraModel().image)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .padding()
                        Image(systemName: camera.seesIpad ? "checkmark.square" : "x.square")
                            .foregroundColor(camera.seesIpad ? .green : .red)
                    }
                    .padding()
                    .onTapGesture {
                        onCameraTap(camera)
                    }
                }
            }
        }
    }
}
