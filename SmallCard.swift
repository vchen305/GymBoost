//
//  SmallCard.swift
//  GymBoost
//
//  Created by Vincent Chen on 3/5/25.
//
import SwiftUI
//Small Card Component
struct SmallCard: View {
    let title: String
    let goal: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            Text("Daily Goal \(goal)")
                .font(.caption)
                .foregroundColor(.gray)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .bold()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
        .shadow(radius: 3)
    }
}



