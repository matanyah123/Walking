//
//  CameraPreview.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 04/06/2025.
//


import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
  let session: AVCaptureSession
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    previewLayer.frame = view.bounds
    view.layer.addSublayer(previewLayer)
    
    DispatchQueue.main.async {
      previewLayer.frame = view.bounds
    }
    
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
      previewLayer.frame = uiView.bounds
    }
  }
}
