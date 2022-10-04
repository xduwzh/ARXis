//
//  CameraList.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 04/10/2022.
//

import SwiftUI

extension Array where Element == Camera {
    func toCameraModels() -> [CameraModel] {
        self.compactMap { camera in
            CAMERAS.first { cameraModel in
                cameraModel.name == camera.cameraModel
            }
        }
    }
}

struct CameraList: View {
    let cameras: [Camera]
    var body: some View {
        ScrollView(.horizontal){
            HStack {
                ForEach(cameras.toCameraModels()) { camera in
                    Image(uiImage: camera.image)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .padding()
                }
            }
        }
    }
}

struct CameraList_Previews: PreviewProvider {
    static var previews: some View {
        CameraList(cameras: [])
    }
}
