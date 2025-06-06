//
//  CameraModel.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 04/06/2025.
//

import Foundation
import AVFoundation
import UIKit
import CoreLocation
import Photos
import ImageIO
import MobileCoreServices

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, CLLocationManagerDelegate {
  let session = AVCaptureSession()
  private let output = AVCapturePhotoOutput()
  private let queue = DispatchQueue(label: "camera.queue")
  
  private let locationManager = CLLocationManager()
  private var currentLocation: CLLocation?
  
  // Store captured photos for the current walk
  @Published var capturedPhotos: [WalkImage] = []
  
  override init() {
    super.init()
    configure()
    configureLocation()
  }
  
  private func configure() {
    session.beginConfiguration()
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
          let input = try? AVCaptureDeviceInput(device: device),
          session.canAddInput(input),
          session.canAddOutput(output) else {
      print("Failed to set up camera input/output")
      return
    }
    
    session.addInput(input)
    session.addOutput(output)
    session.sessionPreset = .photo
    session.commitConfiguration()
  }
  
  private func configureLocation() {
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = locations.last
  }
  
  func startSession() {
    queue.async {
      if !self.session.isRunning {
        self.session.startRunning()
      }
    }
  }
  
  func stopSession() {
    queue.async {
      if self.session.isRunning {
        self.session.stopRunning()
      }
    }
  }
  
  // Clear photos when starting a new walk
  func clearPhotos() {
    capturedPhotos.removeAll()
  }
  
  func takePhoto() {
    let settings = AVCapturePhotoSettings()
    output.capturePhoto(with: settings, delegate: self)
  }
  
  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    guard let photoData = photo.fileDataRepresentation(),
          let source = CGImageSourceCreateWithData(photoData as CFData, nil),
          let uti = CGImageSourceGetType(source) else {
      print("Failed to get photo data")
      return
    }
    
    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, uti, 1, nil) else {
      print("Failed to create destination")
      return
    }
    
    var metadata = photo.metadata
    
    if let location = currentLocation {
      metadata[kCGImagePropertyGPSDictionary as String] = gpsMetadata(for: location)
    }
    
    CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
    CGImageDestinationFinalize(destination)
    
    saveToPhotoLibrary(data: mutableData as Data)
  }
  
  private func saveToPhotoLibrary(data: Data) {
    PHPhotoLibrary.requestAuthorization { [weak self] status in
      if status == .authorized {
        PHPhotoLibrary.shared().performChanges {
          let options = PHAssetResourceCreationOptions()
          let request = PHAssetCreationRequest.forAsset()
          request.addResource(with: .photo, data: data, options: options)
        } completionHandler: { [weak self] success, error in
          if let error = error {
            print("Error saving photo: \(error)")
          } else {
            print("Photo saved successfully")
            // Get the asset identifier and add to our collection
            self?.addPhotoToCollection()
          }
        }
      } else {
        print("Photo Library access not authorized")
      }
    }
  }
  
  private func addPhotoToCollection() {
    DispatchQueue.global(qos: .userInitiated).async {
      let fetchOptions = PHFetchOptions()
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      fetchOptions.fetchLimit = 1

      let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      guard let asset = result.firstObject else {
        print("No image asset found.")
        return
      }

      let walkImage = WalkImage(
        imageType: .camera,
        localIdentifier: asset.localIdentifier,
        fileURL: nil // Could be filled later with PHAssetResourceManager
      )

      DispatchQueue.main.async {
        self.capturedPhotos.append(walkImage)
      }
    }
  }

  private func gpsMetadata(for location: CLLocation) -> [String: Any] {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SS"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    
    var gps = [String: Any]()
    gps[kCGImagePropertyGPSLatitude as String] = abs(location.coordinate.latitude)
    gps[kCGImagePropertyGPSLatitudeRef as String] = location.coordinate.latitude >= 0 ? "N" : "S"
    gps[kCGImagePropertyGPSLongitude as String] = abs(location.coordinate.longitude)
    gps[kCGImagePropertyGPSLongitudeRef as String] = location.coordinate.longitude >= 0 ? "E" : "W"
    gps[kCGImagePropertyGPSAltitude as String] = location.altitude
    gps[kCGImagePropertyGPSAltitudeRef as String] = location.altitude < 0 ? 1 : 0
    gps[kCGImagePropertyGPSTimeStamp as String] = formatter.string(from: location.timestamp)
    gps[kCGImagePropertyGPSDateStamp as String] = DateFormatter.localizedString(from: location.timestamp, dateStyle: .short, timeStyle: .none)
    gps[kCGImagePropertyGPSVersion as String] = "2.2.0.0"
    
    return gps
  }

  func fetchUIImage(for localIdentifier: String, completion: @escaping (UIImage?) -> Void) {
      let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
      guard let asset = assets.firstObject else {
          completion(nil)
          return
      }
      let imageManager = PHImageManager.default()
      let options = PHImageRequestOptions()
      options.isSynchronous = false
      options.deliveryMode = .highQualityFormat

      imageManager.requestImage(for: asset,
                                targetSize: CGSize(width: 300, height: 300),
                                contentMode: .aspectFill,
                                options: options) { image, _ in
          completion(image)
      }
  }

  func deletePhoto(_ photo: WalkImage) {
      guard let id = photo.localIdentifier else { return }

      let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
      PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.deleteAssets(assets)
      }, completionHandler: { [weak self] success, error in
          if let error = error {
              print("Failed to delete asset: \(error)")
          } else if success {
              DispatchQueue.main.async {
                  self?.capturedPhotos.removeAll { $0.localIdentifier == id }
              }
          }
      })
  }

  
}
