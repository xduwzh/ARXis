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
        nil,          "arrow.up",    nil,
        "arrow.left", nil,          "arrow.right",
        nil,          "arrow.down", nil,
    ]
    
    var onArrowUp: (() -> Void)?
    var onArrowLeft: (() -> Void)?
    var onArrowRight: (() -> Void)?
    var onArrowDown: (() -> Void)?
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: ArrowView.spacing) {
            ForEach(0..<9) { index in
                if let icon = icons[index] {
                    Image(systemName: icon)
                        .onTapGesture {
                            switch(icon) {
                                case "arrow.up":
                                    self.onArrowUp?()
                                case "arrow.left":
                                    self.onArrowLeft?()
                                case "arrow.right":
                                    self.onArrowRight?()
                                case "arrow.down":
                                    self.onArrowDown?()
                                default:
                                    break
                            }
                        }
                } else {
                    Image(systemName: "square").opacity(0)
                }
            }
        }
    }
    
}

struct ObjectManipulator: View {
    var onArrowUp: (() -> Void)
    var onArrowLeft: (() -> Void)
    var onArrowRight: (() -> Void)
    var onArrowDown: (() -> Void)
    var onTrashClick: (() -> Void)
    
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
            VStack() {
                Image(systemName: "cone.fill")
                Spacer()
                Image(systemName: "trash.fill")
                    .onTapGesture {
                        onTrashClick()
                    }
            }.padding()
        }
    }
}
