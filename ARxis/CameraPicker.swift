//
//  CameraPicker.swift
//  axisProject
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import SwiftUI

struct CameraPicker: View {
    var onCameraTap: (String) -> Void
    
    var body: some View {
        VStack {
            ForEach(CAMERAS) { camera in
                VStack {
                    Image(uiImage: camera.image)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                    Text(camera.name)
                }
                .onTapGesture {
                    withAnimation(.linear(duration: 0.3)) {
                        onCameraTap(camera.id)
                    }
                }
            }
        }
        .padding()
    }
}

struct CameraPicker_Previews: PreviewProvider {
    static var previews: some View {
        CameraPicker(onCameraTap: {_ in})
    }
}
