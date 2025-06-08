//
//  SharedDataContainer.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 06/06/2025.
//

import SwiftData
import Foundation

@MainActor
class SharedDataContainer {
    static let shared = SharedDataContainer()
    
    private let appGroupID = "group.com.matanyah.WalkTracker"
    
    lazy var container: ModelContainer = {
        let schema = Schema([WalkData.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: containerURL,
            cloudKitDatabase: .none // Or .automatic if you want CloudKit sync
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    private var containerURL: URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("Failed to get container URL for app group: \(appGroupID)")
        }
        return containerURL.appendingPathComponent("WalkData.sqlite")
    }
    
    // Convenience method to get the model context
    var context: ModelContext {
        container.mainContext
    }
}

// MARK: - Data Access Methods
extension SharedDataContainer {
  
  func fetchRecentWalks(limit: Int = 10) -> [WalkData] {
    var descriptor = FetchDescriptor<WalkData>(
      sortBy: [SortDescriptor(\.date, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    
    do {
      return try context.fetch(descriptor)
    } catch {
      print("Failed to fetch recent walks: \(error)")
      return []
    }
  }
  
  func fetchWalkData(for date: Date) -> [WalkData] {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
    
    let predicate = #Predicate<WalkData> { walk in
      walk.date >= startOfDay && walk.date < endOfDay
    }
    
    let descriptor = FetchDescriptor<WalkData>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.startTime, order: .forward)]
    )
    
    do {
      return try context.fetch(descriptor)
    } catch {
      print("Failed to fetch walks for date: \(error)")
      return []
    }
  }
  
  func getTotalStepsToday() -> Int {
    let today = Date()
    let walks = fetchWalkData(for: today)
    return walks.reduce(0) { $0 + $1.steps }
  }
  
  func getTotalDistanceToday() -> Double {
    let today = Date()
    let walks = fetchWalkData(for: today)
    return walks.reduce(0) { $0 + $1.distance }
  }
}
