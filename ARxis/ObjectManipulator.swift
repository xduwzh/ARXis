//
//  ObjectManipulator.swift
//  ARxis
//
//  Created by Aleksy Krolczyk on 27/09/2022.
//

import SwiftUI
import RealityKit

struct ObjectManipulator: View {
    
//    @EnvironmentObject private var arView: ARView
    
    let camera: Camera?
    var body: some View {
        VStack {
            Button("Delete") {
                camera!.entity.removeFromParent()
            }
            Button("Show/hide FOV cone") {
                camera?.enableFOVCone()
            }
        }
        
        
    }
}


struct ObjectManipulator_Previews: PreviewProvider {
    static var previews: some View {
        ObjectManipulator(camera: nil)
    }
}
