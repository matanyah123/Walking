//
//  CustomBottomBar.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI
import WidgetKit
import ActivityKit
import SwiftData

struct CustomBottomBar: View {
  @Binding var started: Bool
  @Binding var tracking: Bool
  @Binding var doYouNeedAGoal: Bool
  @Binding var goal: Double?
  let goalTarget: Int
  @Namespace private var animation
  @Binding var isSearchActive: Bool
  @State private var lastSyncedGoal: Double?
  @Binding var selectedTab: Tab
  @ObservedObject var locationManager: LocationManager
  @ObservedObject var motionManager: MotionManager
  @ObservedObject var liveActivityManager: LiveActivityManager
  @ObservedObject var cameraModel: CameraModel
  @Environment(\.modelContext) private var modelContext
  @Query var savedWalks: [WalkData]
  @State private var timer: Timer? = nil
  @State private var showDeleteConfirmation = false
  @Binding var trackingMode: Int
  @Binding var deepLink: String?
  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true

  var body: some View {
    HStack(spacing: 10) {
      navigationBar

      if selectedTab == .home {
        actionButton
      }
    }
    .onChange(of: isSearchActive) {
      if !isSearchActive {
        // Field closed — check if it matches the default
        if goal == Double(goalTarget) {
          goal = nil
        }
      }
    }
    .onChange(of: deepLink) {
      if deepLink == "group.com.matanyah.WalkTracker.start" {
        startTracking()
      }
    }
    .onAppear {
      // Sync UI state with LocationManager state
      syncUIState()
    }
    .onChange(of: locationManager.isTracking) {
      syncUIState()
    }
    .onChange(of: locationManager.isPaused) {
      syncUIState()
    }
    .onChange(of: locationManager.hasSavedWalk) {
      syncUIState()
    }
    .padding()
  }

  // MARK: - State Synchronization

  private func syncUIState() {
    // Sync the UI bindings with LocationManager state
    DispatchQueue.main.async {
      started = locationManager.isTracking || locationManager.isPaused
      tracking = locationManager.isTracking && !locationManager.isPaused
    }
  }

  // MARK: - UI Components

  private var navigationBar: some View {
    RoundedRectangle(cornerRadius: 25)
      .fill(.ultraThinMaterial)
      .innerShadow(radius: 25)
      .frame(width: isSearchActive ? 50 : 300, height: 50)
      .overlay {
        if isSearchActive {
          backButton
        } else {
          tabButtons
        }
      }
      .onTapGesture {
        if isSearchActive {
          handleBackButtonTap()
        }
      }
  }

  private var backButton: some View {
    Image(systemName: "chevron.left")
      .font(.system(size: 20, weight: .bold))
      .foregroundColor(.white.opacity(0.75))
  }

  private var tabButtons: some View {
    HStack(spacing: 40) {
      Spacer()

      TabIcon(icon: "house.fill", isSelected: selectedTab == .home, namespace: animation)
        .gesture(
          LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
              if selectedTab == .home && !locationManager.isTracking {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                  UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
                trackingMode = 2 // Center + heading
              }
            }
            .simultaneously(with:
                              TapGesture()
              .onEnded {
                if selectedTab == .home && !locationManager.isTracking {
                  DispatchQueue.main.asyncAfter(deadline: .now()) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                  }
                  trackingMode = 1
                }
                handleTabSelection(.home)
              }
                           )
        )

      TabIcon(icon: "line.3.horizontal", isSelected: selectedTab == .walk, namespace: animation)
        .onTapGesture {
          handleTabSelection(.walk)
        }

      TabIcon(icon: "gear", isSelected: selectedTab == .settings, namespace: animation)
        .onTapGesture {
          handleTabSelection(.settings)
        }

      Spacer()
    }
    .font(.system(size: 20, weight: .bold))
  }

  private var actionButton: some View {
    RoundedRectangle(cornerRadius: 25)
      .fill(.ultraThinMaterial)
      .innerShadow(radius: 25)
      .frame(width: isSearchActive ? 300 : 50, height: 50)
      .overlay {
        if isSearchActive {
          if !locationManager.isTracking && !locationManager.isPaused {
            goalInputView
          } else {
            trackingControlsView
          }
        } else {
          runIcon
        }
      }
      .onTapGesture {
        if !isSearchActive {
          handleActionButtonTap()
        }
      }
  }

  private var runIcon: some View {
    Image(systemName: "figure.run")
      .font(.system(size: 20, weight: .bold))
      .foregroundColor((locationManager.isTracking || locationManager.isPaused) ? Color.accentFromSettings.opacity(0.75) : .white.opacity(0.75))
  }

  private var goalInputView: some View {
    HStack {
      TextField("Enter a goal (\(unit ? "KM" : "MI"))", value: $goal, format: .number)
        .keyboardType(.numberPad)
        .foregroundColor(.white)
        .font(.title3)
        .bold()
        .padding()
        .onChange(of: goal) {
          guard let goal, !goal.isNaN else {
            goal = nil
            return
          }
        }

      startButton
    }
    .onAppear {
      if goal == nil && doYouNeedAGoal {
        goal = Double(goalTarget)
      }
    }
  }

  private var startButton: some View {
    Button {
      if goal == 0 {
        goal = nil
      }
      startTracking()
      trackingMode = 0
    } label: {
      Image(systemName: "checkmark")
        .font(.title3)
        .bold()
        .foregroundColor(.white)
        .padding(.all, 7)
        .padding(.horizontal, 3)
        .background(
          BlurView(style: .systemUltraThinMaterialLight)
            .cornerRadius(50)
            .innerShadow(radius: 50)
        )
        .opacity((goal ?? 0) <= 0 ? 0.5 : 0.8)
        .padding(.trailing, 7.5)
    }
    .disabled(doYouNeedAGoal && (goal == nil || goal! <= 0))
  }

  private var trackingControlsView: some View {
    HStack {
      Button {
          showDeleteConfirmation = true
      } label: {
          SetIcon(icon: "trash.fill", isSelected: false, opacityValue: 0.75)
      }
      .alert("Are you sure you want to delete?", isPresented: $showDeleteConfirmation) {
          Button("Delete", role: .destructive) {
              cancelTracking()
              trackingMode = 0
              goal = nil
              UIImpactFeedbackGenerator(style: .soft).impactOccurred()
          }
          Button("Cancel", role: .cancel) {}
      }
      
      Button {
        finishTracking()
        trackingMode = 0
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      } label: {
        SetIcon(icon: "stop.fill", isSelected: false, opacityValue: 0.75)
      }

      Button(action: {
        toggleTracking()
      }) {
        if locationManager.isTracking && !locationManager.isPaused {
          SetIcon(icon: "pause.fill", isSelected: true, opacityValue: 0.75)
        } else {
          SetIcon(icon: "play.fill", isSelected: true, opacityValue: 0.75)
        }
      }
    }
  }

  // MARK: - Actions

  private func handleTabSelection(_ tab: Tab) {
    if selectedTab != tab {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
      }
    }
    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
      selectedTab = tab
    }
  }

  private func handleBackButtonTap() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    withAnimation(.easeInOut.speed(2.5)) {
      isSearchActive.toggle()
      if doYouNeedAGoal && (goal == nil || goal == Double(goalTarget)) {
        goal = Double(goalTarget)
      }
    }
  }

  private func handleActionButtonTap() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
    withAnimation(.easeInOut.speed(2.5)) {
      isSearchActive.toggle()
    }
  }

  private func toggleTracking() {
    UIImpactFeedbackGenerator(style: .soft).impactOccurred()

    if locationManager.isTracking && !locationManager.isPaused {
      // Currently tracking -> pause
      locationManager.pauseTracking()
      motionManager.stopTracking()
    } else if locationManager.isPaused {
      // Currently paused -> resume
      locationManager.resumeTracking()
      motionManager.resumeTracking()
    } else {
      // Not tracking -> start (shouldn't happen in this context)
      locationManager.startTracking()
      motionManager.startTracking()
      startUpdating()
      Task {
        await liveActivityManager.startLiveActivity()
      }
    }
  }

  // MARK: - Tracking Functions

  func startTracking() {
    locationManager.startTracking()
    motionManager.startTracking()
    startUpdating()
    Task {
      await liveActivityManager.startLiveActivity()
    }
  }

  func startUpdating() {
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      Task {
        await liveActivityManager.updateLiveActivity(distance: locationManager.distance, steps: motionManager.stepCount)
      }
    }
  }

  func stopUpdating() {
    timer?.invalidate()
    timer = nil
  }

  private func cancelTracking() {
    locationManager.cancelTracking()
    motionManager.stopTracking()
    motionManager.clearData()
    Task {
      stopUpdating()
      await liveActivityManager.endLiveActivity()
    }
  }

  private func finishTracking() {
      InAppNotificationManager.shared.show(message: "Walk has been saved.\nYou can view it in the app history.\nGood job!")
      locationManager.stopTracking()
      motionManager.stopTracking()
      saveData()
      locationManager.clearData()
      motionManager.clearData()
      WidgetCenter.shared.reloadAllTimelines()
      Task {
        stopUpdating()
        await liveActivityManager.endLiveActivity()
      }
    }

    private func saveData() {
      guard let startTime = locationManager.startTime, let endTime = locationManager.endTime else {
        return
      }

      let newWalk = WalkData(
        date: Date(),
        startTime: startTime,
        endTime: endTime,
        steps: motionManager.stepCount,
        distance: locationManager.distance,
        maxSpeed: locationManager.maxSpeed,
        elevationGain: locationManager.elevationGain,
        elevationLoss: locationManager.elevationLoss,
        route: locationManager.route.map { $0.coordinate },
        walkImages: cameraModel.capturedPhotos // Include captured photos
      )

      // ✅ SwiftData: Save to persistent model context
      modelContext.insert(newWalk)
      do {
        try modelContext.save()
        print("✅ Walk saved with SwiftData and \(cameraModel.capturedPhotos.count) photos")
      } catch {
        print("❌ Error saving walk: \(error)")
      }

      // ✅ Still save the latest walk for the widget
      saveWalkForWidget(walk: newWalk)

      // Clear the photos after saving
      cameraModel.clearPhotos()
    }

  // This function is referenced but not implemented in the original code
  private func saveWalkForWidget(walk: WalkData) {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.matanyah.WalkTracker") else {
      print("Failed to access shared UserDefaults")
      return
    }

    // Save the walk data
    do {
      let encodedWalk = try JSONEncoder().encode(walk)
      sharedDefaults.set(encodedWalk, forKey: "latestWalk")
      print("Successfully saved walk data to shared UserDefaults")
    } catch {
      print("Error encoding walk data: \(error)")
    }
  }
}

struct TabIcon: View {
  var icon: String
  var isSelected: Bool
  var namespace: Namespace.ID

  var body: some View {
    ZStack {
      if isSelected {
        BlurView(style: .systemUltraThinMaterialLight)
          .cornerRadius(25)
          .innerShadow(radius: 25)
          .matchedGeometryEffect(id: "selectedTab", in: namespace)
          .padding(.vertical, 10.0)
          .frame(width: 120)
          .opacity(0.75)
      }

      Image(systemName: icon)
        .foregroundColor(.white.opacity(isSelected ? 1 : 0.75))
    }
  }
}

#Preview {
  @Previewable @State var deepLink: String?
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}
