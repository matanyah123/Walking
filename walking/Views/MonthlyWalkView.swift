//
//  MonthlyWalkView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 03/06/2025.
//

import SwiftUI
import SwiftData

struct WalkDay: Identifiable {
  let id = UUID()
  let date: Date
  let totalDistance: Double
  let goalRatio: Double // 0.0 to 4.0+ based on goal achievement
  let walkCount: Int
}

struct MonthlyWalkView: View {
  let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  @AppStorage("goalTarget", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var goalTarget: Int = 5000

  @State private var contributions: [[WalkDay]] = []
  @State private var selectedDate: Date = Date()
  @State private var walkHistory: [WalkData] = []
  @State private var bannerPosition: CGPoint = .zero
  @State private var bannerText: String = ""
  @State private var showBanner = false

  // Inject the model context for SwiftData
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ZStack {
      VStack(alignment: .leading, spacing: 8) {
        HStack{
          Image(systemName: "chevron.left")
            .font(.title2)
            .fontWeight(.semibold)
            .onTapGesture {
              changeMonth(by: -1)
            }
          Text(monthYearTitle)
            .font(.title2)
            .fontWeight(.semibold)
          if !isCurrentMonth {
            Image(systemName: "chevron.right")
              .font(.title2)
              .fontWeight(.semibold)
              .onTapGesture {
                changeMonth(by: 1)
              }
          }
        }

        HStack(spacing: 22) {
          ForEach(weekDays, id: \.self) { day in
            Text(" \(day)")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }
        VStack(alignment: .leading, spacing: 10) {
          ForEach(Array(contributions.enumerated()), id: \.offset) { _, week in
            HStack(spacing: 10) {
              ForEach(week, id: \.date) { day in
                GeometryReader { geo in
                  Rectangle()
                    .fill(color(for: day.goalRatio))
                    .frame(width: 35, height: 35)
                    .cornerRadius(10)
                    .overlay(
                      Text("\(Calendar.current.component(.day, from: day.date))")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(day.goalRatio > 0 ? .white : .secondary)
                    )
                    .onTapGesture {
                      let globalOrigin = geo.frame(in: .global).origin
                      bannerPosition = CGPoint(x: globalOrigin.x - 10, y: globalOrigin.y - 150)

                      let formatter = DateFormatter()
                      formatter.dateStyle = .medium
                      bannerText = "\(formatter.string(from: day.date))\n\(String(format: "%.1f", day.totalDistance))m · \(day.walkCount) walk\(day.walkCount == 1 ? "" : "s")"

                      withAnimation(.spring()) {
                        showBanner = true
                      }

                      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation {
                          showBanner = false
                        }
                      }
                    }
                }
                .frame(width: 35, height: 35) // Important: to match GeometryReader size
              }
            }
          }
        }
      }
      .padding(.horizontal)
      // Banner overlay
      if showBanner {
        Text(bannerText)
          .font(.caption)
          .padding(8)
          .background(.ultraThinMaterial)
          .cornerRadius(8)
          .innerShadow(radius: 8)
          .position(bannerPosition)
          .transition(.opacity.combined(with: .scale))
      }
    }
    .task {
      await loadWalkHistory()
      generateMonthlyContributions()
    }
    .onChange(of: goalTarget) {
      generateMonthlyContributions()
    }
    .onChange(of: selectedDate) {
      generateMonthlyContributions()
    }
  }

  // MARK: - Computed
  private var monthYearTitle: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yyyy"
    return formatter.string(from: selectedDate)
  }

  private var isCurrentMonth: Bool {
    Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
  }

  // MARK: - Helpers
  private func changeMonth(by offset: Int) {
    if let newDate = Calendar.current.date(byAdding: .month, value: offset, to: selectedDate), newDate <= Date() {
      selectedDate = newDate
    }
  }

  // Async fetch from SwiftData model
  private func loadWalkHistory() async {
    do {
      let walks: [WalkData] = try await modelContext.fetch(FetchDescriptor<WalkData>(sortBy: [SortDescriptor(\.date, order: .forward)]))
      walkHistory = walks.map { walk in
        WalkData(
          date: walk.date,
          startTime: walk.startTime,
          endTime: walk.endTime,
          steps: Int(walk.steps),
          distance: walk.distance,
          maxSpeed: walk.maxSpeed,
          elevationGain: walk.elevationGain,
          elevationLoss: walk.elevationLoss,
          route: walk.route // Assuming route is stored as [CLLocationCoordinate2D] or convertible
        )
      }
    } catch {
      print("Failed to fetch walks from SwiftData: \(error)")
      walkHistory = []
    }
  }

  private func generateMonthlyContributions() {
    var calendar = Calendar.current
    calendar.firstWeekday = 1 // Sunday

    guard let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start,
          let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end else {
      contributions = []
      return
    }

    var weeks: [[WalkDay]] = []
    var currentWeek: [WalkDay] = []

    var currentDate = startOfMonth
    while currentDate < endOfMonth {
      let walkDay = createWalkDay(for: currentDate)
      currentWeek.append(walkDay)

      if currentWeek.count == 7 {
        weeks.append(currentWeek)
        currentWeek = []
      }

      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
      currentDate = nextDate
    }

    if !currentWeek.isEmpty {
      weeks.append(currentWeek)
    }

    contributions = weeks
  }

  private func createWalkDay(for date: Date) -> WalkDay {
    let calendar = Calendar.current
    let dayWalks = walkHistory.filter { calendar.isDate($0.date, inSameDayAs: date) }

    let totalDistance = dayWalks.reduce(0) { $0 + $1.distance }
    let goalRatio = Double(goalTarget) > 0 ? Double(totalDistance) / Double(goalTarget) : 0

    return WalkDay(date: date, totalDistance: totalDistance, goalRatio: goalRatio, walkCount: dayWalks.count)
  }

  func color(for goalRatio: Double) -> Color {
    switch goalRatio {
    case 0..<0.01:
      return Color.gray.opacity(0.2)
    case 0.01..<0.25:
      return Color.accentFromSettings.opacity(0.3)
    case 0.25..<0.5:
      return Color.accentFromSettings.opacity(0.5)
    case 0.5..<0.75:
      return Color.accentFromSettings.opacity(0.7)
    case 0.75..<1.0:
      return Color.accentFromSettings.opacity(0.9)
    default: // 1.0 and above (goal achieved or exceeded)
      return Color.accentFromSettings
    }
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

struct YearlyWalkView: View {
  @Query(sort: \WalkData.date, order: .forward) private var walkHistory: [WalkData]
  
  @AppStorage("goalTarget", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var goalTarget: Int = 5000
  
  @State private var contributions: [[WalkDay]] = []
  @State private var bannerPosition: CGPoint = .zero
  @State private var bannerText: String = ""
  @State private var showBanner = false
  @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
  
  var body: some View {
    ZStack{
      VStack(alignment: .leading, spacing: 10) {
        // Header
        HStack{
          Image(systemName: "chevron.left")
            .font(.title3)
            .fontWeight(.semibold)
            .onTapGesture {
              changeYear(by: -1)
            }
          Text("Walk Activity - \(String(selectedYear))")
            .font(.title3)
            .fontWeight(.semibold)
          if !isCurrentYear {
            Image(systemName: "chevron.right")
              .font(.title3)
              .fontWeight(.semibold)
              .onTapGesture {
                changeYear(by: 1)
              }
          }
        }
        .padding([.leading, .trailing])
        // Month labels
        HStack(alignment: .top, spacing: 3) {
          ForEach(0..<12, id: \.self) { monthIndex in
            VStack(spacing: 2) {
              Text(monthName(for: monthIndex))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 25)
            }
          }
        }
        .padding(.horizontal)
        
        // Calendar grid
        HStack(alignment: .top, spacing: 3) {
          ForEach(0..<12, id: \.self) { monthIndex in
            if monthIndex < contributions.count {
              VStack(spacing: 3) {
                ForEach(0..<contributions[monthIndex].count, id: \.self) { dayIndex in
                  let day = contributions[monthIndex][dayIndex]
                  GeometryReader { geo in
                    Rectangle()
                      .fill(color(for: day.goalRatio))
                      .frame(width: 25, height: 16)
                      .cornerRadius(2)
                      .overlay {
                        if day.goalRatio > 0 {
                          Text("\(day.walkCount)")
                            .font(.caption)
                            .foregroundColor(day.goalRatio > 0.3 ? .white : .gray)
                            .bold()
                        }
                      }
                      .onTapGesture {
                        let globalOrigin = geo.frame(in: .global).origin
                        bannerPosition = CGPoint(x: globalOrigin.x + 13, y: globalOrigin.y)
                        
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        bannerText = "\(formatter.string(from: day.date))\n\(String(format: "%.1f", day.totalDistance))m · \(day.walkCount) walk\(day.walkCount == 1 ? "" : "s")"
                        
                        withAnimation(.spring()) {
                          showBanner = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                          withAnimation {
                            showBanner = false
                          }
                        }
                      }
                  }
                  .frame(width: 25, height: 16) // Must define fixed frame outside GeometryReader
                }
              }
            }
          }
        }
        .padding(.horizontal)
      }
      if showBanner {
        Text(bannerText)
          .font(.caption)
          .padding(8)
          .background(.ultraThinMaterial)
          .cornerRadius(8)
          .innerShadow(radius: 8)
          .position(bannerPosition)
          .transition(.opacity.combined(with: .scale))
      }
    }
    .safeAreaInset(edge: .bottom) {
      VStack(alignment: .leading){
        legendView
          .padding(.horizontal, 35.0)
        Color.clear.frame(height: 50)
      }
    }
    .onAppear {
      generateYearlyContributions()
    }
    .onChange(of: goalTarget) {
      generateYearlyContributions()
    }
    .onChange(of: walkHistory) {
      generateYearlyContributions()
    }
    .onChange(of: selectedYear) {
      generateYearlyContributions()
    }
  }
  
  private var isCurrentYear: Bool {
    selectedYear >= Calendar.current.component(.year, from: Date())
  }
  
  // MARK: - Day Square Component
  private func daySquare(for day: WalkDay) -> some View {
    Rectangle()
      .fill(color(for: day.goalRatio))
      .frame(width: 25, height: 16)
      .cornerRadius(2)
      .overlay {
        if day.goalRatio > 0 {
          Text("\(day.walkCount)")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(day.goalRatio > 0.3 ? .white : .gray)
        }
      }
      .onTapGesture {
        showDayBanner(for: day)
      }
  }
  
  // MARK: - Banner Management
  private func showDayBanner(for day: WalkDay) {
    // Calculate banner position (simplified - you might want to adjust this)
    bannerPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: 200)
    
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    bannerText = "\(formatter.string(from: day.date))\n\(String(format: "%.1f", day.totalDistance))m · \(day.walkCount) walk\(day.walkCount == 1 ? "" : "s")"
    
    withAnimation(.spring()) {
      showBanner = true
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      withAnimation {
        showBanner = false
      }
    }
  }
  
  // MARK: - Year Navigation
  private func changeYear(by offset: Int) {
    let newYear = selectedYear + offset
    let currentYear = Calendar.current.component(.year, from: Date())
    
    if newYear <= currentYear {
      selectedYear = newYear
    }
  }
  
  // MARK: - Legend View
  private var legendView: some View {
    VStack(alignment: .leading, spacing: 1) {
      HStack {
        Text("Less")
          .font(.caption2)
          .foregroundColor(.secondary)
        
        HStack(spacing: 2) {
          ForEach(0..<6) { level in
            Rectangle()
              .fill(color(for: Double(level) * 0.2))
              .frame(width: 10, height: 10)
              .cornerRadius(2)
          }
        }
        
        Text("More")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      
      Text("Total walks this year: \(totalWalksThisYear)")
        .font(.caption2)
        .foregroundColor(.secondary)
    }
  }
  
  // MARK: - Computed Properties
  private var totalWalksThisYear: Int {
    let calendar = Calendar.current
    
    return walkHistory.filter { walk in
      calendar.component(.year, from: walk.date) == selectedYear
    }.count
  }
  
  // MARK: - Helper Methods
  private func monthName(for index: Int) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let calendar = Calendar.current
    let date = calendar.date(from: DateComponents(year: selectedYear, month: index + 1, day: 1)) ?? Date()
    return formatter.string(from: date)
  }
  
  private func generateYearlyContributions() {
    let calendar = Calendar.current
    var data: [[WalkDay]] = []
    
    for month in 1...12 {
      var monthData: [WalkDay] = []
      let daysInMonth = calendar.range(of: .day, in: .month,
                                       for: calendar.date(from: DateComponents(year: selectedYear, month: month, day: 1))!)!.count
      
      for day in 1...daysInMonth {
        let date = calendar.date(from: DateComponents(year: selectedYear, month: month, day: day))!
        let walkDay = createWalkDay(for: date)
        monthData.append(walkDay)
      }
      data.append(monthData)
    }
    
    contributions = data
  }
  
  private func createWalkDay(for date: Date) -> WalkDay {
    let calendar = Calendar.current
    let dayWalks = walkHistory.filter { walk in
      calendar.isDate(walk.date, inSameDayAs: date)
    }
    
    let totalDistance = dayWalks.reduce(0) { $0 + $1.distance }
    let goalRatio = Double(goalTarget) > 0 ? totalDistance / Double(goalTarget) : 0
    
    return WalkDay(
      date: date,
      totalDistance: totalDistance,
      goalRatio: goalRatio,
      walkCount: dayWalks.count
    )
  }
  
  func color(for goalRatio: Double) -> Color {
    switch goalRatio {
    case 0..<0.01:
      return Color.gray.opacity(0.2)
    case 0.01..<0.25:
      return Color.accentFromSettings.opacity(0.3)
    case 0.25..<0.5:
      return Color.accentFromSettings.opacity(0.5)
    case 0.5..<0.75:
      return Color.accentFromSettings.opacity(0.7)
    case 0.75..<1.0:
      return Color.accentFromSettings.opacity(0.9)
    default: // 1.0 and above (goal achieved or exceeded)
      return Color.accentFromSettings
    }
  }
}
#Preview {
  ContentView()
    .preferredColorScheme(.dark)
}
/*
#Preview("Yearly View") {
  YearlyWalkView()
}
*/
