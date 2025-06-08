//
//  SetIcon.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 26/05/2025.
//

import SwiftUI

struct SetIcon: View {
  var icon: String
  var isSelected: Bool
  var opacityValue: Double
  
  var body: some View {
    ZStack {
      BlurView(style: .systemUltraThinMaterialLight)
        .cornerRadius(25)
        .innerShadow(radius: 25)
        .padding(.all, 5.0)
        .opacity(isSelected ? opacityValue : opacityValue - 0.5)
        .overlay{
          Image(systemName: icon)
            .foregroundColor(
              .white
                .opacity(isSelected ? 1 : opacityValue)
            )
        }
    }
  }
}
