//  ContentView.swift
//  ObjectManipulator
//
//  Created by Adam Korytowski on 04/10/2022.
//

import SwiftUI

struct ArrowView: View {
    static let width: CGFloat = 20
    static let spacing: CGFloat = 7

    let columns = [
        GridItem(.fixed(ArrowView.width)),
        GridItem(.fixed(ArrowView.width)),
        GridItem(.fixed(ArrowView.width)),
    ]

    let icons = [
        nil, "arrow.up", nil,
        "arrow.left", nil, "arrow.right",
        nil, "arrow.down", nil,
    ]

    var onArrowUp: (() -> Void)?
    var onArrowLeft: (() -> Void)?
    var onArrowRight: (() -> Void)?
    var onArrowDown: (() -> Void)?

    var body: some View {
        LazyVGrid(columns: columns, spacing: ArrowView.spacing) {
            ForEach(0..<9) { index in
                if let icon = icons[index] {
                    Button(action: {
                        switch icon {
                        case "arrow.up": onArrowUp?()
                        case "arrow.left": onArrowLeft?()
                        case "arrow.right": onArrowRight?()
                        case "arrow.down": onArrowDown?()
                        default: break
                        }
                    }, label: {
                        Image(systemName: icon)
                    }
                    )
                } else {
                    Image(systemName: "square").opacity(0)
                }
            }
        }
    }
}

struct ObjectManipulator: View {
    var onArrowUp: () -> Void
    var onArrowLeft: () -> Void
    var onArrowRight: () -> Void
    var onArrowDown: () -> Void
    var onTrashClick: () -> Void
    var onConeClick: () -> Void
    var onSliderValueChanged: (Float) -> Void

    @State var fovActive: Bool
    @State var fovHeight: Float = 1

    var fovHeightRange: ClosedRange<Float> = 0.1...5


    var body: some View {
        VStack {
            HStack {
                ArrowView(
                    onArrowUp: onArrowUp,
                    onArrowLeft: onArrowLeft,
                    onArrowRight: onArrowRight,
                    onArrowDown: onArrowDown
                )
                .font(.system(size: 20))
                .padding()
                Spacer()
                VStack {
                    Button(action: {
                        fovActive = !fovActive
                        onConeClick()
                    }, label: {
                        Image(systemName: fovActive ? "cone.fill" : "cone")
                    })
                    Spacer()
                    Button(action: {
                        onTrashClick()
                    }, label: {
                        Image(systemName: "trash.fill")
                    })
                }.padding()
            }


            VStack(alignment: .leading, spacing: 0) {
                Text("FOV Height")
                        .font(.system(size: 15))
                        .padding(.leading)
                Slider(value: $fovHeight, in: fovHeightRange) {
                } minimumValueLabel: {
                    Text(String(format: "%.2f", fovHeightRange.lowerBound))
                } maximumValueLabel: {
                    Text(String(format: "%.2f", fovHeightRange.upperBound))
                }
                .onChange(of: fovHeight, perform: onSliderValueChanged)
                .padding()
            }


        }
        .frame(width: 200, height: 200)
        .background(RadialGradient(gradient: Gradient(colors: gradientColors), center: .center, startRadius: 70, endRadius: 10))
        .cornerRadius(20)
    }
    
    let gradientColors = [
        Color(uiColor: UIColor(white: 0.8, alpha: 1)),
        Color(uiColor: UIColor(white: 0.75, alpha: 1)),
        Color(uiColor: UIColor(white: 0.7, alpha: 1))
    ]
}

func doNothing() {}
func doNothing2(_: Float) {}

struct ObjectManipulator_Previews: PreviewProvider {
    static var previews: some View {
        ObjectManipulator(
            onArrowUp: doNothing,
            onArrowLeft: doNothing,
            onArrowRight: doNothing,
            onArrowDown: doNothing,
            onTrashClick: doNothing,
            onConeClick: doNothing,
            onSliderValueChanged: doNothing2,
            fovActive: false
        )
    }
}
