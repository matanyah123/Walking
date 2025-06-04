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
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: options)
                } completionHandler: { success, error in
                    if let error = error {
                        print("Error saving photo: \(error)")
                    } else {
                        print("Photo saved successfully")
                    }
                }
            } else {
                print("Photo Library access not authorized")
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
}
