//
//  BlurView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 14/05/2025.
//
import SwiftUI

struct BlurView: UIViewRepresentable {
  let style: UIBlurEffect.Style
  
  func makeUIView(context: Context) -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
    return view
  }
  
  func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct InnerShadowModifierGeneral: ViewModifier {
  let radius: CGFloat

  func body(content: Content) -> some View {
    content.overlay(
      RoundedRectangle(cornerRadius: radius)
        .stroke(Color.gray, lineWidth: 1)
        .shadow(color: .white.opacity(0.3), radius: 5, x: 4, y: -4)
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .shadow(color: .black, radius: 5, x: -4, y: 4)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    )
  }
}

extension View {
  func innerShadow(radius: CGFloat) -> some View {
    self.modifier(InnerShadowModifierGeneral(radius: radius))
  }
}

struct ChromaticAberrationModifier: ViewModifier {
  let radius: CGFloat
  let offset: CGFloat

  func body(content: Content) -> some View {
    ZStack {
      aberratedLayer(content: content)
        .mask(radialMask()) // Soft fade toward center
      content // Original layer on top for sharpness
    }
    .compositingGroup()
    .blendMode(.screen)
  }

  private func aberratedLayer(content: Content) -> some View {
    ZStack {
      content
        .foregroundColor(.red)
        .blur(radius: radius)
        .offset(x: -offset)
      content
        .foregroundColor(.green)
        .blur(radius: radius)
        .offset(x: offset)
      content
        .foregroundColor(.blue)
        .blur(radius: radius)
    }
  }

  private func radialMask() -> some View {
    RadialGradient(
      gradient: Gradient(colors: [.black, .clear]),
      center: .center,
      startRadius: 10,
      endRadius: 200
    )
    .scaleEffect(1.5)
    .edgesIgnoringSafeArea(.all)
  }
}

extension View {
  func chromaticAberration(radius: CGFloat = 0.5, offset: CGFloat = 3.5, isOn: Bool = true) -> some View {
    Group {
      if isOn {
        self.modifier(ChromaticAberrationModifier(radius: radius, offset: offset))
      } else {
        self
      }
    }
  }
}


#Preview{
  ZStack{
    Circle().frame(width: 1000)
      .foregroundColor(.white)
    Circle().frame(width: 1000)
      .offset(x: -50, y: 500)
      .foregroundColor(.green)
    Circle().frame(width: 1000)
      .offset(x: 300, y: -100)
      .foregroundColor(.pink)
      BlurView(style: .systemThickMaterial)
        .frame(width: 300, height: 700)
        .cornerRadius(50)
        .innerShadow(radius: 50)
    VStack{
      Text("SwiftUI Chromatic ✨")
        .font(.system(size: 26, weight: .bold))
        .chromaticAberration(radius: 0.5, offset: 3.5, isOn: true)
    }
  }
}
