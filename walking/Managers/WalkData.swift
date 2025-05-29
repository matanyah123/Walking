//
//  WalkData.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//
import Foundation
import CoreLocation

extension WalkData {
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        return formatter.string(from: duration) ?? "0m"
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

struct WalkData: Codable, Identifiable {
    let id: UUID
    var date: Date
    let startTime: Date
    let endTime: Date
    let steps: Int
    let distance: Double
    let maxSpeed: Double
    let elevationGain: Double
    let elevationLoss: Double
    let route: [CLLocationCoordinate2D]
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
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
        self.route = route
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, startTime, endTime, steps, distance, maxSpeed, elevationGain, elevationLoss, route
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decode(Date.self, forKey: .endTime)
        steps = try container.decode(Int.self, forKey: .steps)
        distance = try container.decode(Double.self, forKey: .distance)
        maxSpeed = try container.decode(Double.self, forKey: .maxSpeed)
        elevationGain = try container.decode(Double.self, forKey: .elevationGain)
        elevationLoss = try container.decode(Double.self, forKey: .elevationLoss)
        route = try container.decode([CLLocationCoordinate2D].self, forKey: .route)
    }

    func encode(to encoder: Encoder) throws {
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
    }
}

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
