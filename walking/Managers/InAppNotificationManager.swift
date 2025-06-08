//
//  InAppNotificationManager.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 05/06/2025.
//


import SwiftUI

class InAppNotificationManager: ObservableObject {
  static let shared = InAppNotificationManager()
  
  @Published var message: String = ""
  @Published var isVisible: Bool = false
  
  private var timer: Timer?
  
  private init() {}
  
  func show(message: String, duration: TimeInterval = 5.0) {
    self.message = message
    self.isVisible = true
    
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
      self.dismiss()
    }
  }
  
  func dismiss() {
    withAnimation {
      self.isVisible = false
    }
  }
}
