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
    case id, date, startTime, endTime, steps, distance, maxSpeed, elevationGain, elevationLoss, route
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
    try container.encode(route, forKey: .route) // Use computed property
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
    var date: Date
    var startTime: Date
    var endTime: Date
    var steps: Int
    var distance: Double
    var maxSpeed: Double
    var elevationGain: Double
    var elevationLoss: Double
    @Attribute(.externalStorage) var routeData: Data

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

    init(date: Date, startTime: Date, endTime: Date, steps: Int, distance: Double, maxSpeed: Double, elevationGain: Double, elevationLoss: Double, route: [CLLocationCoordinate2D]) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.steps = steps
        self.distance = distance
        self.maxSpeed = maxSpeed
        self.elevationGain = elevationGain
        self.elevationLoss = elevationLoss

        // Encode route to Data
        if let data = try? JSONEncoder().encode(route) {
            self.routeData = data
        } else {
            self.routeData = Data()
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

      self.init(
          date: date,
          startTime: startTime,
          endTime: endTime,
          steps: steps,
          distance: distance,
          maxSpeed: maxSpeed,
          elevationGain: elevationGain,
          elevationLoss: elevationLoss,
          route: route
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
