//
//  HomePageView.swift
//  GymBoost
//
//  Created Vincent Chen on 3/5/25.
//

import SwiftUI

struct HomepageView: View {
    var body: some View {
        VStack {
            // Header Section
            HStack {
                Image(systemName: "person.circle")
                    .font(.title)
                    .foregroundColor(.black)
                Spacer()
                Text("GymBoost")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.orange)
                Spacer()
            }
            .padding(.horizontal)
            
            // Calories Card
            VStack {
                Text("Calories")
                    .font(.headline)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.orange, lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                    Text("650\nNeeded")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                }
                .frame(width: 100, height: 100)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Daily Goal").font(.caption)
                        Text("2750").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Consumed").font(.caption)
                        Text("2100").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Burned").font(.caption)
                        Text("300").bold()
                            .foregroundColor(.red)
                    }
                }
                .padding()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
            .shadow(radius: 3)
            
            // Water and Steps Cards
            HStack(spacing: 10) {
                SmallCard(title: "Water", goal: "115oz", value: "56oz", icon: "drop.fill", color: .blue)
                SmallCard(title: "Steps", goal: "10000", value: "2100", icon: "figure.walk", color: .green)
            }
            
            // Weight Chart Placeholder
            VStack {
                Text("Weight")
                    .font(.headline)
                Spacer()
                Text("Graph Placeholder")
                Spacer()
            }
            .frame(height: 120)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
            .shadow(radius: 3)
            .padding(.horizontal)
            
            Spacer()
            
            // Bottom Navigation Bar
            HStack {
                BottomTabItem(icon: "house", label: "Home")
                BottomTabItem(icon: "dumbbell", label: "Workouts")
                BottomTabItem(icon: "leaf", label: "Nutrition", highlighted: true)
                BottomTabItem(icon: "line.3.horizontal", label: "More")
            }
            .frame(height: 60)
            .background(Color.white.shadow(radius: 2))
        }
        .background(Color(UIColor.systemGray6))
    }
}
