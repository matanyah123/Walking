//
//  BackgroundView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI

struct BackgroundView: View {
  var body: some View {
    ZStack{
      Circle().frame(width: 1000)
        .foregroundColor(.white)
      Circle().frame(width: 1000)
        .offset(x: -50, y: 500)
        .foregroundColor(.green.opacity(0.5))
      Circle().frame(width: 1000)
        .offset(x: 300, y: -100)
        .foregroundColor(.blue.opacity(0.5))
      BlurView(style: .systemThickMaterial)
        .edgesIgnoringSafeArea(.all)
    }
  }
}
