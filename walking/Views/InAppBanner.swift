//
//  InAppBanner.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 05/06/2025.
//


import SwiftUI

struct InAppBanner: View {
  @ObservedObject var manager = InAppNotificationManager.shared
  @StateObject private var viewModel = ContentViewModel.shared
  
  var body: some View {
    if manager.isVisible {
      VStack {
        HStack {
          Text(manager.message)
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 12)
          Spacer()
          Button(action: {
            manager.dismiss()
          }) {
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.white)
              .padding(.trailing)
          }
        }
        .background(BlurView(style: .systemUltraThinMaterialDark).innerShadow(radius: 10))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 50) // for status bar
        .onTapGesture {
          viewModel.isSearchActive = false
          viewModel.selectedTab = .walk
          manager.dismiss()
        }
        Spacer()
      }
      .transition(.move(edge: .top).combined(with: .opacity))
      .animation(.spring(), value: manager.isVisible)
    }
  }
}
