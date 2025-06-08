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
  @Environment(\.dismiss) private var dismiss

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

  var body: some View {
    ZStack(alignment: .top) {
      VStack(spacing: 20) {
        GeometryReader { geo in
          CameraPreview(session: cameraModel.session)
            .ignoresSafeArea()
            .gesture(
              DragGesture(minimumDistance: 0)
                .onEnded { value in
                  let location = value.location
                  cameraModel.focus(at: location, viewSize: geo.size)
                }
            )
        }
        .frame(height: 400)

        // Existing photo grid etc...
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

        HStack{
          // Camera switch button
          Button(action: {
            dismiss()
          }) {
            Image(systemName: "x.square.fill")
              .font(.system(size: 30))
              .foregroundColor(.white)
              .padding()
              .background(Color.black.opacity(0.5))
              .clipShape(Circle())
              .padding([.top,.trailing], 10)
          }

          Spacer()

          // Capture button
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

          Spacer()

          // Camera switch button
          Button(action: {
            cameraModel.switchCamera()
          }) {
            Image(systemName: "camera.rotate.fill")
              .font(.system(size: 30))
              .foregroundColor(.white)
              .padding()
              .background(Color.black.opacity(0.5))
              .clipShape(Circle())
              .padding([.top,.trailing], 10)
          }
        }.padding(.bottom ,50)
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

#Preview {
  @Previewable @State var deepLink: String?
  ContentView()
    .preferredColorScheme(.dark)
}
/*
#Preview {
  let cameraModel = CameraModel()
  let selectedDetent = Binding.constant(PresentationDetent.medium)
  return CameraView(cameraModel: cameraModel, darkMode: true, selectedDetent: selectedDetent)
}
*/
