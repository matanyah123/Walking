//
//  CameraView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 04/06/2025.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct CameraView: View {
  @ObservedObject var cameraModel: CameraModel
  let darkMode: Bool
  @Binding var selectedDetent: PresentationDetent

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

  var body: some View {
    ZStack(alignment: .top) {
      VStack(spacing: 20) {
          CameraPreview(session: cameraModel.session)
            .ignoresSafeArea()

        if selectedDetent == .large && !cameraModel.capturedPhotos.isEmpty {
            ScrollView {
              LazyVGrid(columns: columns, spacing: 10) {
                ForEach(cameraModel.capturedPhotos) { photo in
                  if let id = photo.localIdentifier {
                    PhotoView(localIdentifier: id)
                      .contextMenu {
                        Button(role: .destructive) {
                          cameraModel.deletePhoto(photo)
                        } label: {
                          Label("Delete", systemImage: "trash").tint(.red)
                        }
                      }
                  } else {
                    Image(systemName: "photo")
                      .resizable()
                      .scaledToFit()
                      .frame(width: 100, height: 100)
                      .foregroundColor(.gray)
                  }
                }
              }
            }
        }

        Button(action: {
          cameraModel.takePhoto()
        }) {
          Image(systemName: "camera.circle.fill")
            .font(.system(size: 90))
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 4)
        }
        .background(
          Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 120, height: 120)
            .shadow(radius: 10)
        )
      }
    }
    .background(Color.black.ignoresSafeArea())
    .onAppear { cameraModel.startSession() }
    .onDisappear { cameraModel.stopSession() }
  }
}

struct PhotoView: View {
  let localIdentifier: String
  @State private var uiImage: UIImage? = nil
  @ObservedObject var cameraModel = CameraModel()

  var body: some View {
    Group {
      if let image = uiImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
          .frame(width: 100, height: 100)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .shadow(radius: 4)
      } else {
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)

          ProgressView()
        }
        .onAppear {
          cameraModel.fetchUIImage(for: localIdentifier) { image in
            withAnimation { self.uiImage = image }
          }
        }
      }
    }
  }
}
