//
//  CameraList.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 04/10/2022.
//

import SwiftUI

struct CameraList: View {
    let cameras: [CameraInScene]
    var onCameraTap: (CameraInScene) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(cameras) { camera in
                    VStack {
                        Image(uiImage: camera.model.image)
                            .resizable()
                            .frame(width: 100, height: 100)
                            .cornerRadius(10)
                            .padding()
                        HStack {
                            Image(systemName: camera.seesIpad ? "checkmark.square" : "x.square")
                                .foregroundColor(camera.seesIpad ? .green : .red)
                            PixelDensityVisualizer(pixelDensity: camera.pixelDensity)
                                .frame(width: 100, height: 30)
                        }
                    }
                    .padding()
                    .onTapGesture {
                        onCameraTap(camera)
                    }
                }
            }
        }
            .background(Color(white: 0.5, opacity: 0.5))
    }
}
