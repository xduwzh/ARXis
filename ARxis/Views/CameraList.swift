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

    var selectedCameraId: ObjectIdentifier?

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(cameras) { camera in
                    VStack {
                        ZStack {
                            if let selectedCameraId, camera.id == selectedCameraId {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.green)
                                    .frame(width: 105, height: 105)
                            }
                            Image(uiImage: camera.model.image)
                                .resizable()
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                                .padding()

                        }

                        HStack {
                            if camera.seesIpad {
                                PixelDensityVisualizer(pixelDensity: camera.pixelDensity)
                            } else {
                                Image(systemName:"x.square").foregroundColor(.red)
                            }
                        }
                        .frame(width: 100, height: 30)
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
