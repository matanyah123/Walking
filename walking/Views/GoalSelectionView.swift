//
//  GoalSelectionView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 19/06/2025.
//

import SwiftUI

struct GoalSelectionView: View {
	@State var goal = 0.0
	var body: some View {
		VStack (alignment: .leading){
			Text("Set a goal").font(.largeTitle.bold())
			Slider(value: $goal).tint(.green)
		}.background(Color.accentFromSettings.gradient)
	}
}

#Preview {
	GoalSelectionView()
}
