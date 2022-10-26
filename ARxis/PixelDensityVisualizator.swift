//
//  PixelDensitySlider.swift
//  ObjectManipulator
//
//  Created by Adam Korytowski on 25/10/2022.
//

import SwiftUI


struct PixelDensityVisualizator: View {
    @Binding var value: Double
    var bounds: ClosedRange<Float> = 0...1
    var separators: [Double] = []
    
    let calculateColorFunc: (Double) -> Color
    
    func getPointerOffset(pointerDiameter: CGFloat, width: CGFloat) -> CGFloat {
        let x1 = pointerDiameter / CGFloat(2)
        let x2 = CGFloat(value / 100) * (width - pointerDiameter)
        let x3 = width / CGFloat(2)
        return x1 + x2 - x3
    }
    
    func getSeparators(pointerDiameter: CGFloat, width: CGFloat) -> some View {
        ForEach(separators, id: \.self){ separator in
            Rectangle()
                .frame(width: .pi)
                .offset(x: pointerDiameter/2 + separator * (width - pointerDiameter) / 100 - width / 2)
        }
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let circleDiameter = geometry.size.height * 0.4
            
            VStack (spacing: 0) {
                
                Image(systemName: "arrowtriangle.down.fill")
                    .resizable()
                    .frame(width: 13, height: 13)
                    .foregroundColor(.black)
                    .frame(width: circleDiameter, height: circleDiameter)
                    .offset(x: getPointerOffset(pointerDiameter: circleDiameter, width: width))
                    .padding(.bottom, 2)
                
                ZStack {
                    RoundedRectangle(cornerRadius: circleDiameter)
                        .background(RoundedRectangle(cornerRadius: circleDiameter).stroke(.black, lineWidth: 4))
                        .foregroundColor(calculateColorFunc(value))
                    
                    getSeparators(pointerDiameter: circleDiameter, width: width)
                    
                }
            }
        }
    }
}

struct PixelDensitySlider: View {
    @State var pixelDensity: Double = 50
    
    var accentColor: Color {
        switch pixelDensity {
            case _ where pixelDensity < 25:
                return .red
            case _ where pixelDensity < 50:
                return .orange
            case _ where pixelDensity < 75:
                return .yellow
            default:
                return .green
        }
        
    }
    
    func calcColor(_ pixelDensity: Double) -> Color {
        switch pixelDensity {
            case _ where pixelDensity < 25:
                return .red
            case _ where pixelDensity < 50:
                return .orange
            case _ where pixelDensity < 75:
                return .yellow
            default:
                return .green
        }
    }
    
    var body: some View {
        Slider(value: $pixelDensity, in: 0...100)
            .accentColor(accentColor)
            .padding()
        PixelDensityVisualizator(value: $pixelDensity, separators: [25, 50, 75], calculateColorFunc: calcColor)
            .frame(width: 300, height: 50)
    }
    
    
    
    
}

struct PixelDensitySlider_Previews: PreviewProvider {
    static var previews: some View {
        PixelDensityVisualizator(value: .constant(50), bounds: 0...100, calculateColorFunc: {_ in .white})
            .frame(width: 300, height: 100)
    }
}
