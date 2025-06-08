//
//  WalkData.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//

import Foundation
import CoreLocation
import SwiftData

extension WalkData {
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: duration) ?? "0m"
    }
}

extension WalkData: Codable {
  enum CodingKeys: String, CodingKey {
    case id, date, startTime, endTime, steps, distance, maxSpeed, elevationGain, elevationLoss, route, name
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(id, forKey: .id)
    try container.encode(date, forKey: .date)
    try container.encode(startTime, forKey: .startTime)
    try container.encode(endTime, forKey: .endTime)
    try container.encode(steps, forKey: .steps)
    try container.encode(distance, forKey: .distance)
    try container.encode(maxSpeed, forKey: .maxSpeed)
    try container.encode(elevationGain, forKey: .elevationGain)
    try container.encode(elevationLoss, forKey: .elevationLoss)
    try container.encode(route, forKey: .route)
    try container.encodeIfPresent(name, forKey: .name) // Use encodeIfPresent for optional
  }
}

extension WalkData {
    var maxSpeedInKmH: Double {
        return maxSpeed * 3.6 // 1 m/s = 3.6 km/h
    }

    var maxSpeedInMph: Double {
        return maxSpeed * 2.23694 // 1 m/s = 2.23694 mph
    }
}

@Model
final class WalkData {
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage)
    var date: Date
    var startTime: Date
    var endTime: Date
    var steps: Int
    var distance: Double
    var maxSpeed: Double
    var walkImagesData: Data = Data()
    var elevationGain: Double
    var elevationLoss: Double
    @Attribute(.externalStorage) var routeData: Data
    var name: String? // Optional walk name

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    // Computed property to get route coordinates
    var route: [CLLocationCoordinate2D] {
        get {
            guard let coordinates = try? JSONDecoder().decode([CLLocationCoordinate2D].self, from: routeData) else {
                return []
            }
            return coordinates
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            routeData = data
        }
    }

  var walkImages: [WalkImage] {
      get {
          (try? JSONDecoder().decode([WalkImage].self, from: walkImagesData)) ?? []
      }
      set {
          if let encoded = try? JSONEncoder().encode(newValue) {
              walkImagesData = encoded
          }
      }
  }

  init(
      date: Date,
      startTime: Date,
      endTime: Date,
      steps: Int,
      distance: Double,
      maxSpeed: Double,
      elevationGain: Double,
      elevationLoss: Double,
      route: [CLLocationCoordinate2D],
      walkImages: [WalkImage] = [],
      name: String? = nil // Optional parameter with default nil
  ) {
      self.id = UUID()
      self.date = date
      self.startTime = startTime
      self.endTime = endTime
      self.steps = steps
      self.distance = distance
      self.maxSpeed = maxSpeed
      self.elevationGain = elevationGain
      self.elevationLoss = elevationLoss
      self.name = name

      if let data = try? JSONEncoder().encode(route) {
          self.routeData = data
      } else {
          self.routeData = Data()
      }

      if let imageData = try? JSONEncoder().encode(walkImages) {
          self.walkImagesData = imageData
      } else {
          self.walkImagesData = Data()
      }
  }

  required convenience init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      let id = try container.decode(UUID.self, forKey: .id)
      let date = try container.decode(Date.self, forKey: .date)
      let startTime = try container.decode(Date.self, forKey: .startTime)
      let endTime = try container.decode(Date.self, forKey: .endTime)
      let steps = try container.decode(Int.self, forKey: .steps)
      let distance = try container.decode(Double.self, forKey: .distance)
      let maxSpeed = try container.decode(Double.self, forKey: .maxSpeed)
      let elevationGain = try container.decode(Double.self, forKey: .elevationGain)
      let elevationLoss = try container.decode(Double.self, forKey: .elevationLoss)
      let route = try container.decode([CLLocationCoordinate2D].self, forKey: .route)
      let name = try container.decodeIfPresent(String.self, forKey: .name) // Use decodeIfPresent

      self.init(
          date: date,
          startTime: startTime,
          endTime: endTime,
          steps: steps,
          distance: distance,
          maxSpeed: maxSpeed,
          elevationGain: elevationGain,
          elevationLoss: elevationLoss,
          route: route,
          name: name
      )

      self.id = id
  }
}

// Keep the CLLocationCoordinate2D Codable extension for encoding/decoding
extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(CLLocationDegrees.self)
        let longitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}

extension WalkData {
    static var dummy: WalkData {
        let now = Date()
        let startTime = Calendar.current.date(byAdding: .minute, value: -45, to: now)!
        let center = CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
        let route = generateHeartRoute(center: center, radius: 0.0005)

        return WalkData(
            date: now,
            startTime: startTime,
            endTime: now,
            steps: 3200,
            distance: 3500.0,
            maxSpeed: 2.5,
            elevationGain: 30,
            elevationLoss: 25,
            route: route,
            name: "Morning Heart Walk" // Example name for dummy data
        )
    }
}

func generateHeartRoute(center: CLLocationCoordinate2D, radius: Double = 0.0003, resolution: Int = 300) -> [CLLocationCoordinate2D] {
    let points = stride(from: 0.0, through: 2 * Double.pi, by: 2 * Double.pi / Double(resolution)).map { t -> CLLocationCoordinate2D in
        let x = 16 * pow(sin(t), 3)
        let y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)

        // Normalize to [-1, 1] range
        let normX = x / 18.0
        let normY = y / 17.0

        let lat = center.latitude + normY * radius
        let lon = center.longitude + normX * radius
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    return points
}
