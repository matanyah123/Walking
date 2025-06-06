//
//  WalkActivityView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 03/06/2025.
//
import SwiftUI
import WidgetKit
import SwiftData

struct WalkActivityView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \WalkData.date, order: .reverse) private var walkHistory: [WalkData]

  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true

  // Get the last 7 walks sorted by date (most recent first)
  private var recentWalks: [WalkData] {
      Array(walkHistory.sorted { $0.date > $1.date }.prefix(3))
  }

  // Group the recent walks by date, same logic as WalkHistoryView
  private var groupedRecentWalks: [(String, [WalkData])] {
      let grouped = Dictionary(grouping: recentWalks) { walk in
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd"
          return formatter.string(from: walk.date)
      }
      return grouped.sorted { $0.key > $1.key }
  }

  @State private var showDeleteConfirmation = false
  @State private var walkToDelete: WalkData?
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Activity")) {
          NavigationLink(destination: YearlyWalkView()) {
            Text("Full Yearly Activity")
          }
          MonthlyWalkView()
        }
        Section(header: Text("History"), footer: Text("\n\n")) {
          NavigationLink(destination: WalkHistoryView()) {
            Text("Full History")
          }
          if !groupedRecentWalks.isEmpty {
            ForEach(groupedRecentWalks, id: \.0) { date, walks in
              Section(header: Text(formattedDisplayDate(from: date)).font(.headline)) {
                ForEach(walks) { walk in
                  NavigationLink(destination: WalkDetailView(walk: walk)) {
                    HStack {
                      VStack(alignment: .leading, spacing: 4) {
                        Text("\(walk.distance, specifier: "%.2f") \(unit ? "meters" : "miles")")
                          .font(.body)
                          .fontWeight(.medium)
                        
                        HStack {
                          Text("Steps: \(walk.steps)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                          
                          Spacer()
                          
                          Text(formattedTime(walk.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if walk.duration > 0 {
                          Text("Duration: \(formattedDuration(walk.duration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                      }
                    }
                    .padding(.vertical, 6)
                  }
                  .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                      walkToDelete = walk
                      showDeleteConfirmation = true
                    } label: {
                      Label("Delete", systemImage: "trash").tint(.red)
                    }
                    .tint(.red)
                  }
                  .swipeActions(edge: .leading) {
                    Button {
                      shareWalkSnapshot(walk: walk)
                    } label: {
                      Label("Share", systemImage: "square.and.arrow.up")
                    }
                  }
                }
              }
            }
          } else {
            ContentUnavailableView(
              "No Recent Walks",
              systemImage: "figure.walk.circle",
              description: Text("Start tracking your walks to see them here")
            )
          }
        }
        .alert("Are you sure?", isPresented: $showDeleteConfirmation, presenting: walkToDelete) { walk in
            Button("Delete", role: .destructive) {
                deleteWalk(walk)
            }
            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("This action cannot be undone.")
        }
      }.navigationTitle("Your Activity")
    }
  }

  private func deleteWalk(_ walk: WalkData) {
      modelContext.delete(walk)
      do {
          try modelContext.save()
          // Optional: update widget after deleting
          WidgetCenter.shared.reloadAllTimelines()
      } catch {
          print("Failed to delete walk: \(error)")
      }
  }

  private func formattedDisplayDate(from isoDate: String) -> String {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      if let date = formatter.date(from: isoDate) {
          // Show relative date for recent walks
          if Calendar.current.isDateInToday(date) {
              return "Today"
          } else if Calendar.current.isDateInYesterday(date) {
              return "Yesterday"
          } else {
              formatter.dateStyle = .medium
              return formatter.string(from: date)
          }
      }
      return isoDate
  }

  private func formattedTime(_ date: Date) -> String {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      return formatter.string(from: date)
  }

  private func formattedDuration(_ duration: TimeInterval) -> String {
      let hours = Int(duration) / 3600
      let minutes = (Int(duration) % 3600) / 60
      let seconds = Int(duration) % 60

      if hours > 0 {
          return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
      } else {
          return String(format: "%02d:%02d", minutes, seconds)
      }
  }
}

#Preview {
  WalkActivityView()
}
