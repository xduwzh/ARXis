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
            ForEach(0 ..< 9) { index in
                if let icon = icons[index] {
                    Button(action: {
                        switch icon {
                            case "arrow.up": self.onArrowUp?()
                            case "arrow.left": self.onArrowLeft?()
                            case "arrow.right": self.onArrowRight?()
                            case "arrow.down": self.onArrowDown?()
                            default: break
                        }
                    }, label: {
                        Image(systemName: icon)}
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
    
    @State var coneActive: Bool
    
    var body: some View {
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
                    coneActive = !coneActive
                    onConeClick()
                }, label: {
                    Image(systemName: coneActive ? "cone.fill" : "cone")
                })
                Spacer()
                Button(action: {
                    onTrashClick()
                }, label: {
                    Image(systemName: "trash.fill")
                })
            }.padding()
        }
        .frame(width: 180, height: 100)
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
            coneActive: false
        )
    }
}
