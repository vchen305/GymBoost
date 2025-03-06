//
//  BottomTabItem.swift
//  GymBoost
//
//  Created by Vincent Chen on 3/5/25.
//
import SwiftUI
// Bottom Tab Bar Item
struct BottomTabItem: View {
    let icon: String
    let label: String
    var highlighted: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(highlighted ? .orange : .black)
            Text(label)
                .font(.caption)
        }
        .frame(maxWidth: .infinity)
    }
}
