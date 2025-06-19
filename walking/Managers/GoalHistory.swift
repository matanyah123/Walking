//
//  GoalHistory.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 17/06/2025.
//

import Foundation
import SwiftData

@Model
class GoalHistory: Identifiable {
	var id: String
	@Attribute var goal: Int
	@Attribute var numberOfUses: Int = 0

	init(goal: Int) {
		self.id = UUID().uuidString
		self.goal = goal
		self.numberOfUses = 1
	}

	func incrementNumberOfUses() {
		self.numberOfUses += 1
	}
}
