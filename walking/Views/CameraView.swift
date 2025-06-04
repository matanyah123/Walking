//
//  CameraView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 04/06/2025.
//


import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraModel = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(session: cameraModel.session)
                .ignoresSafeArea()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .shadow(radius: 5)
                    }

                    Spacer()
                }

                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            cameraModel.startSession()
        }
        .onDisappear {
            cameraModel.stopSession()
        }
    }
}
