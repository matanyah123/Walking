//
//  LiveActions.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 08/06/2025.
//
import SwiftUI

class LiveActions: ObservableObject {
  static let shared = LiveActions()

  @Published var openCamera = false
  @Published var toggleWalk = false
  @Published var startWalk = false
}
