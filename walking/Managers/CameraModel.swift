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
  
  // Camera devices & input
  private var currentDevice: AVCaptureDevice?
  private var currentInput: AVCaptureDeviceInput?
  
  // Exposure & focus
  @Published var exposureValue: Float = 0.0  // between minExposureTargetBias & maxExposureTargetBias
  
  // Camera position (back = default)
  @Published var cameraPosition: AVCaptureDevice.Position = .back
  
  // Store captured photos for the current walk
  @Published var capturedPhotos: [WalkImage] = []
  
  override init() {
    super.init()
    configure(devicePosition: cameraPosition)
    configureLocation()
  }
  
  private func configure(devicePosition: AVCaptureDevice.Position) {
    session.beginConfiguration()
    
    // Remove old inputs
    if let currentInput = currentInput {
      session.removeInput(currentInput)
    }
    
    // Select device
    guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: devicePosition) else {
      print("Failed to get camera device for position \(devicePosition)")
      session.commitConfiguration()
      return
    }
    
    do {
      let input = try AVCaptureDeviceInput(device: device)
      
      // Add input & output
      if session.canAddInput(input) {
        session.addInput(input)
        currentInput = input
        currentDevice = device
      } else {
        print("Cannot add input to session")
      }
      
      if !session.outputs.contains(output), session.canAddOutput(output) {
        session.addOutput(output)
      }
      
      session.sessionPreset = .photo
      
      // Lock device to configure exposure mode and focus mode defaults
      try device.lockForConfiguration()
      if device.isExposureModeSupported(.continuousAutoExposure) {
        device.exposureMode = .continuousAutoExposure
      }
      if device.isFocusModeSupported(.continuousAutoFocus) {
        device.focusMode = .continuousAutoFocus
      }
      device.unlockForConfiguration()
      
    } catch {
      print("Error configuring device input: \(error.localizedDescription)")
    }
    
    session.commitConfiguration()
  }
  
  func switchCamera() {
    cameraPosition = (cameraPosition == .back) ? .front : .back
    queue.async { [weak self] in
      guard let self = self else { return }
      self.session.stopRunning()
      self.configure(devicePosition: self.cameraPosition)
      self.session.startRunning()
    }
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
  
  // MARK: Exposure control
  
  func setExposure(value: Float) {
    guard let device = currentDevice else { return }
    do {
      try device.lockForConfiguration()
      let clampedValue = max(min(value, device.maxExposureTargetBias), device.minExposureTargetBias)
      device.setExposureTargetBias(clampedValue) { _ in }
      device.unlockForConfiguration()
      DispatchQueue.main.async {
        self.exposureValue = clampedValue
      }
    } catch {
      print("Failed to set exposure: \(error)")
    }
  }
  
  // MARK: Focus control with tap
  
  func focus(at point: CGPoint, viewSize: CGSize) {
    guard let device = currentDevice else { return }
    let focusPoint = CGPoint(x: point.y / viewSize.height, y: 1.0 - (point.x / viewSize.width))
    do {
      try device.lockForConfiguration()
      if device.isFocusPointOfInterestSupported {
        device.focusPointOfInterest = focusPoint
        device.focusMode = .autoFocus
      }
      if device.isExposurePointOfInterestSupported {
        device.exposurePointOfInterest = focusPoint
        device.exposureMode = .autoExpose
      }
      device.unlockForConfiguration()
    } catch {
      print("Failed to set focus/exposure point: \(error)")
    }
  }
  
  // MARK: Photos & Location (unchanged from your original)
  
  private func configureLocation() {
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    currentLocation = locations.last
  }
  
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
        fileURL: nil
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
