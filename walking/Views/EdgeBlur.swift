//
//  EdgeBlur.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 28/05/2025.
//
import SwiftUI

struct EdgeBlur: View {
  enum Direction {
    case top, bottom
  }

  var direction: Direction
  var opacity: Double = 0.5

  var body: some View {
    LinearGradient(
      gradient: Gradient(stops: [
        .init(color: Color.black.opacity(opacity), location: 0),
        .init(color: Color.black.opacity(0.0), location: 1)
      ]),
      startPoint: direction == .top ? .top : .bottom,
      endPoint: direction == .top ? .bottom : .top
    )
    .blur(radius: 8)
    .frame(height: 200)
    .allowsHitTesting(false)
  }
}


#Preview {
  EdgeBlur(direction: .bottom)
}
