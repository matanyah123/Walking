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
  @AppStorage("isPlusUser", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var isPlusUser: Bool = false
  @AppStorage("isHighlightLastWalk", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var isHighlightLastWalk: Bool = false

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
  @State private var highlightLastWalk = false
  @State private var selectedWalkForEditing: WalkData?
  @State private var editingName = ""
  @Binding var isLastOneGlows: Bool

  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Activity")) {
          NavigationLink {
            if isPlusUser {
            YearlyWalkView()
            } else {
              NavigationLink {
                PaymentWall()
              } label: {
                ContentUnavailableView("You need to upgrade to Plus to view this feature", systemImage: "plus")
              }
            }
          } label: {
            Text("Full Yearly Activity")
          }
          if isPlusUser {
            MonthlyWalkView()
          } else {
            NavigationLink {
              PaymentWall()
            } label: {
              ContentUnavailableView("You need to upgrade to Plus to view this feature", systemImage: "plus")
            }
          }
        }
        Section(header: Text("History")) {
          NavigationLink(destination: WalkHistoryView()) {
            Text("Full History")
          }
          if !groupedRecentWalks.isEmpty {
            ForEach(groupedRecentWalks, id: \.0) { date, walks in
              Section(header: Text(formattedDisplayDate(from: date)).font(.headline)) {
                ForEach(walks) { walk in
                  NavigationLink(destination: WalkDetailView(walk: walk)) {
                    VStack(alignment: .leading, spacing: 4) {
                      Text(displayName(for: walk))
                        .font(.body)
                        .fontWeight(.medium)

                      Text("\(walk.distance, specifier: "%.2f") \(unit ? "meters" : "miles") • \(walk.steps) steps")
                        .font(.caption)
                        .foregroundColor(.secondary)

                      Text(walk.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .cornerRadius(10)
                  }
                  .listRowBackground(
                    isLastWalk(walk) && highlightLastWalk ?
                    Color.accentFromSettings.opacity(0.3) : nil
                  )
                  .animation(.easeInOut, value: highlightLastWalk)
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
                      if isPlusUser {
                        shareWalkSnapshot(walk: walk)
                      } else {
                        InAppNotificationManager.shared.show(message: "The feature is locked, buy Plus to unlock.")
                      }
                    } label: {
                      Label("Share", systemImage: "square.and.arrow.up")
                        .tint(isPlusUser ? Color.accentFromSettings : Color.gray)
                    }
                    Button {
                      selectedWalkForEditing = walk
                      editingName = walk.name ?? ""
                    } label: {
                      Label("Edit", systemImage: "pencil")
                    }.tint(.orange)
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
      }
      .navigationTitle("Your Activity")
      .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 80)
      }
      .onAppear {
        //MARK: -
        if !isHighlightLastWalk {
          highlightLastWalk = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeInOut) {
              highlightLastWalk = false
            }
          }
          isHighlightLastWalk = true
        }
      }
      .onChange(of: isLastOneGlows) {
        if isLastOneGlows {
          withAnimation(.easeInOut) {
            highlightLastWalk = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation(.easeInOut) {
              highlightLastWalk = false
              isLastOneGlows = false
            }
          }
        }
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
    .sheet(item: $selectedWalkForEditing) { walk in
      NavigationView {
        VStack(spacing: 20) {
          Text("Edit Walk Name")
            .font(.title2)
            .fontWeight(.semibold)

          TextField("Enter a name", text: $editingName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)

          Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
              selectedWalkForEditing = nil
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
              saveWalkName(walk: walk, newName: editingName)
              selectedWalkForEditing = nil
            }
          }
        }
      }
    }
  }

  // Helper function to determine if this is the most recent walk
  private func isLastWalk(_ walk: WalkData) -> Bool {
    guard let mostRecentWalk = recentWalks.first else { return false }
    return walk.id == mostRecentWalk.id
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

  // Added the missing saveWalkName function
  private func saveWalkName(walk: WalkData, newName: String) {
    walk.name = newName.isEmpty ? nil : newName
    do {
      try modelContext.save()
    } catch {
      print("Failed to save walk name: \(error)")
    }
  }

  // Helper function to get display name for a walk
  private func displayName(for walk: WalkData) -> String {
    return walk.name ?? "Walk on \(formattedDate(walk.date))"
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

  // Added missing formattedDate function
  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
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
  @Previewable @State var isLastOneGlows: Bool = true
  WalkActivityView(isLastOneGlows: $isLastOneGlows)
}
