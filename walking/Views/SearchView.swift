//
//  SearchView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 19/06/2025.
//

import SwiftUI
import SwiftData

struct SearchView: View {
	@Binding var started: Bool
	@State var text: String = ""
	@Binding var selectedTab: Tab
	@Environment(\.colorScheme) private var colorScheme
	@Environment(\.modelContext) private var context
	@Query(sort: \GoalHistory.goal) private var goals: [GoalHistory]

	var body: some View {
		if #available(iOS 26, *) {
			ScrollView () {
				VStack() {
					if text.isEmpty {
						if !topGoals.isEmpty {
							List {
								Section(header: Text("Most Used Goals")) {
									ForEach(topGoals) { goal in
										Button {
											text = String(goal.goal)
											start()
										} label: {
											Text("\(goal.goal) debug - Uses: \(goal.numberOfUses)")
												.foregroundStyle(.blue)
										}
									}
								}
							}
							.scrollContentBackground(.hidden)
							.background(Color.clear)
							.frame(height: CGFloat(topGoals.count) * 70 + 30)
							.scrollDisabled(true)
						}
						//PhotoGridView()
						//.colorScheme(colorScheme == //.light ? .dark : .light)
					} else {
						List {
							Section(header: Text("Matching Goals")) {
								ForEach(filteredGoals) { goal in
									Button {
										text = String(goal.goal)
										start()
									} label: {
										Text("\(goal.goal) debug - Uses: \(goal.numberOfUses)")
											.foregroundStyle(.blue)
									}
								}.onDelete(perform: deleteGoals)
							}
						}
						.scrollContentBackground(.hidden)
						.background(Color.clear)
						.frame(height: 800)
						.ignoresSafeArea()
					}
				}
				.padding(.horizontal)
				.ignoresSafeArea(edges: .horizontal)
			}
			.safeAreaInset(edge: .top) {
				HStack {
					GlassEffectContainer {
						TextField("Enter a goal", text: $text)
							.font(.title2.bold())
							.padding()
							.tint(Color.secondary)
							.keyboardType(.numberPad)
							.onSubmit {
								start()
							}

						Button {
							start()
						} label: {
							Text("go")
								.font(.title2.bold())
								.foregroundStyle(Color.secondary)
								.padding()
						}
					}
					.glassEffect(.regular.interactive())
					.padding()
				}
			}
			//.background(Color.blue.gradient)
		} else {
			Text("Unsupported platform")
		}
	}
	private func start() {
		if text != "" {
			started = true
			selectedTab = .home
			addGoal()
			text = ""
		} else {
			started = true
			selectedTab = .home
		}
	}

	private var filteredGoals: [GoalHistory] {
		if text.isEmpty {
			return goals
		} else {
			return goals.filter { "\($0.goal)".contains(text) }
		}
	}

	private var topGoals: [GoalHistory] {
		goals
			.sorted { a, b in
				if a.numberOfUses == b.numberOfUses {
					return a.id > b.id // Prefer most recent (UUID as timestamp proxy)
				} else {
					return a.numberOfUses > b.numberOfUses // Prefer higher usage
				}
			}
			.prefix(3)
			.map { $0 }
	}

	private func addGoal() {
		guard let goalValue = Int(text) else { return }

		// Check if the goal already exists
		if let existingGoal = goals.first(where: { $0.goal == goalValue }) {
			existingGoal.incrementNumberOfUses()
			print("Goal exists! Incremented number of uses. \(goalValue)")
		} else {
			let newGoal = GoalHistory(goal: goalValue)
			context.insert(newGoal)
			print("New goal added! \(goalValue)")
		}

		text = ""
	}

	private func deleteGoals(at offsets: IndexSet) {
		for index in offsets {
			let goalToDelete = filteredGoals[index]
			context.delete(goalToDelete)
		}
	}
}

#Preview {
	SearchView(started: .constant(false), selectedTab: .constant(.search))
		.modelContainer(for: GoalHistory.self)
		.preferredColorScheme(.dark)
}
