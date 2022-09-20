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
            Text("🎥")
                .font(.system(size: 100))
                .onDrag {
                    return NSItemProvider(object: "1" as NSString )
                }
                
            Text("📽")
                .font(.system(size: 100))
                .onDrag {
                    return NSItemProvider(object: "2" as NSString )
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
