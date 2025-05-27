//
//  CustomBottomBar.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI
import WidgetKit
import ActivityKit

struct CustomBottomBar: View {
    @Binding var started: Bool
    @Binding var tracking: Bool
    @Binding var doYouNeedAGoal: Bool
    @Binding var goal: Double?
    let goalTarget: Int
    @Namespace private var animation
    @State private var isSearchActive: Bool = false
    @State private var lastSyncedGoal: Double?
    @Binding var selectedTab: Tab
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var motionManager: MotionManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @State private var timer: Timer? = nil
    @Binding var trackingMode: Int
    @Binding var deepLink: String?
    @AppStorage("mapStyleDarkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var mapStyleDarkMode: Bool = true

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
          if deepLink == "start" {
                startTracking()
            }
        }
        .padding()
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
            .foregroundColor(.white.opacity(0.4))
    }

  private var tabButtons: some View {
    HStack(spacing: 40) {
      Spacer()

      TabIcon(icon: "house.fill", isSelected: selectedTab == .home, namespace: animation)
        .gesture(
          LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
              if selectedTab == .home && !started {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                  UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
                trackingMode = 2 // Center + heading
              }
            }
            .simultaneously(with:
              TapGesture()
                .onEnded {
                  if selectedTab == .home && !started{
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
                    if !started {
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
            .foregroundColor(started ? Color.accentFromSettings.opacity(0.4) : .white.opacity(0.4))
    }

    private var goalInputView: some View {
        HStack {
            TextField("Enter a goal (meters)", value: $goal, format: .number)
                .keyboardType(.numberPad)
                .foregroundColor(.white)
                .font(.title3)
                .bold()
                .padding()
                .onChange(of: goal) { newValue in
                    guard let newValue = goal, !newValue.isNaN else {
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
                        .innerShadow(radius: 50)                )
                .opacity((goal ?? 0) <= 0 ? 0.5 : 0.8)
                .padding(.trailing, 7.5)
        }
        .disabled(doYouNeedAGoal && (goal == nil || goal! <= 0))
    }

    private var trackingControlsView: some View {
        HStack {
            Button {
                trashTracking()
              trackingMode = 0
                goal = nil
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            } label: {
                SetIcon(icon: "trash.fill", isSelected: false, opacityValue: 0.75)
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
                if tracking {
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

        if tracking {
          locationManager.stopTracking()
          motionManager.stopTracking()
        } else {
            if started {
                locationManager.resumeTracking()
                motionManager.resumeTracking()
            } else {
                locationManager.startTracking()
                motionManager.startTracking()
            }
        }

        tracking.toggle()
        started = true
    }

    // MARK: - Tracking Functions

    func startTracking() {
        started = true
        tracking = true
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

    private func trashTracking() {
        started = false
        tracking = false
        locationManager.stopTracking()
        motionManager.stopTracking()
        locationManager.clearData()
        motionManager.clearData()
        locationManager.clearRoute()
        Task {
            stopUpdating()
            await liveActivityManager.endLiveActivity()
        }
    }

    private func finishTracking() {
        started = false
        tracking = false
        locationManager.stopTracking()
        motionManager.stopTracking()
        saveData()
        locationManager.clearData()
        motionManager.clearData()
        locationManager.clearRoute()
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
            route: locationManager.route.map { $0.coordinate }
        )

        let completedWalk = newWalk
        saveWalkForWidget(walk: completedWalk)

        var savedWalks = loadSavedWalks()
        savedWalks.append(newWalk)

        if let encoded = try? JSONEncoder().encode(savedWalks) {
            UserDefaults.standard.set(encoded, forKey: "walkHistory")
        }

        // Save the latest walk for the widget in the shared app group
        if let latestEncoded = try? JSONEncoder().encode(newWalk) {
            UserDefaults(suiteName: "group.com.matanyah.WalkTracker")?.set(latestEncoded, forKey: "latestWalk")
            WidgetCenter.shared.reloadAllTimelines() // Refresh widget timeline immediately
        }
    }

    private func loadSavedWalks() -> [WalkData] {
        if let savedData = UserDefaults.standard.data(forKey: "walkHistory"),
           let walkHistory = try? JSONDecoder().decode([WalkData].self, from: savedData) {
            return walkHistory
        }
        return []
    }

    // This function is referenced but not implemented in the original code
    private func saveWalkForWidget(walk: WalkData) {
        // Implementation would go here
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
          .innerShadow(radius: 25)          .matchedGeometryEffect(id: "selectedTab", in: namespace)
          .padding(.vertical, 10.0)
          .frame(width: 120)
          .opacity(0.75)
      }

      Image(systemName: icon)
        .foregroundColor(.white.opacity(isSelected ? 1 : 0.75))
    }
  }
}


// Add this function to the file where you save walks (likely ContentView.swift)
func saveWalkForWidget(walk: WalkData) {
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


#Preview {
  @Previewable @State var deepLink: String?
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}
