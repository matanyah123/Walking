//
//  WalkImage.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 05/06/2025.
//


import Foundation
import CoreLocation

struct WalkImage: Codable, Identifiable {
    enum ImageType: String, Codable {
        case gallery
        case camera
    }

    var id: UUID = UUID()
    var imageType: ImageType
    var localIdentifier: String? // For Photos framework images
    var fileURL: URL?            // For generated images in app's file system
}
