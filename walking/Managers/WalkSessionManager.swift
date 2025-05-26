//
//  WalkSessionManager.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 21/05/2025.
//
import SwiftUI
import Combine
import WidgetKit
import CoreLocation
import MapKit

// MARK: - Main Session Manager (Singleton)
class WalkSessionManager: ObservableObject {
    static let shared = WalkSessionManager()

    // Core managers - all as singletons
    @Published var locationManager = LocationManager.shared
    @Published var motionManager = MotionManager.shared
    @Published var liveActivityManager = LiveActivityManager.shared
    @Published var contentViewModel = ContentViewModel.shared

    private init() {
        // Private init to ensure singleton
    }

    func start() {
        print("Starting walk session from WalkSessionManager")
        contentViewModel.deepLinkStart()
    }
}
