//
//  CameraPicker.swift
//  axisProject
//
//  Created by Aleksy Krolczyk on 20/09/2022.
//

import SwiftUI

struct CameraPicker: View {
    var body: some View {
        VStack {
            ForEach(CAMERAS) { camera in
                Image(uiImage: camera.image)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .onDrag {
                        return NSItemProvider(object: camera.id as NSString)
                    }
            }
        }
        .padding()
    }
}

struct CameraPicker_Previews: PreviewProvider {
    static var previews: some View {
        CameraPicker()
    }
}
