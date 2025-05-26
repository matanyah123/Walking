//
//  colorExtention.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 19/05/2025.
//


import SwiftUI


// MARK: - Color Extension
extension Color {
    static var accentFromSettings: Color {
        guard
            let data = UserDefaults(suiteName: "group.com.matanyah.WalkTracker")?.data(forKey: "accentColor"),
            let decoded = try? JSONDecoder().decode(CodableColor.self, from: data)
        else {
            return .blue
        }
        return decoded.color
    }
}


// MARK: - CodableColor Definition
struct CodableColor: Codable, Equatable, Hashable {
  let red: Double
  let green: Double
  let blue: Double
  let opacity: Double
  static let `default` = lavenderBlue

  var color: Color {
    Color(red: red, green: green, blue: blue, opacity: opacity)
  }

  init(_ color: Color) {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)

    self.red = Double(r)
    self.green = Double(g)
    self.blue = Double(b)
    self.opacity = Double(a)
  }

  init(red: Double, green: Double, blue: Double, opacity: Double) {
    self.red = red
    self.green = green
    self.blue = blue
    self.opacity = opacity
  }

  // Matanyah's Favorite Colors
  static let lavenderBlue = CodableColor(red: 124 / 255, green: 128 / 255, blue: 213 / 255, opacity: 1.0)
  static let turquoiseMint = CodableColor(red: 99 / 255, green: 215 / 255, blue: 197 / 255, opacity: 1.0)
  static let vibrantOrange = CodableColor(red: 255 / 255, green: 141 / 255, blue: 58 / 255, opacity: 1.0)
}
