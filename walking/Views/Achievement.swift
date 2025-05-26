//
//  Achievement.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI

struct Achievement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var unlocked: Bool = false
}

struct AchievementsView: View {
    @State private var currentIndex = 0
    
    let achievements: [Achievement] = [
        Achievement(name: "First Milestone", description: "Walk 5 kilometers for the first time"),
        Achievement(name: "Speed Demon", description: "Achieve a maximum speed of 10 m/s"),
        Achievement(name: "Consistency is Key", description: "Walk every day for a week")
    ]
    
    var body: some View {
        VStack {
            Text("Achievements").font(.title)
            
            Text(achievements[currentIndex].name)
                .font(.headline)
                .padding()
            
            Text(achievements[currentIndex].description)
                .padding()
            
            HStack {
                Button("Previous") {
                    currentIndex = max(currentIndex - 1, 0)
                }.disabled(currentIndex == 0)
                Spacer()
                Button("Next") {
                    currentIndex = min(currentIndex + 1, achievements.count - 1)
                }.disabled(currentIndex == achievements.count - 1)
            }.padding()
            
            Spacer()
        }.padding()
    }
}
