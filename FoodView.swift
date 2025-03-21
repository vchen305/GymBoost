import SwiftUI

// MARK: - Data Models

struct UserMeal {
    let name: String
    let foods: [UserFood]
}

struct UserFood: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
}

// MARK: - Food Search View

struct FoodSearchView: View {
    let meal: UserMeal
    @State private var searchText: String = ""
    @State private var selectedFood: UserFood?

    private let foodOptions: [UserFood] = [
        UserFood(name: "Chicken Breast, cooked, with skin", calories: 455),
        UserFood(name: "Scrambled Eggs", calories: 140),
        UserFood(name: "White Rice, cooked", calories: 200),
        UserFood(name: "Apple, medium", calories: 95),
        UserFood(name: "Almonds, raw", calories: 170)
    ]
    
    var filteredFood: [UserFood] {
        searchText.isEmpty ? foodOptions : foodOptions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack {
            // Search Bar
            TextField("Search for food", text: $searchText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

            // Food List
            ScrollView {
                VStack(spacing: 8) { // Spacing between each food item
                    ForEach(filteredFood) { food in
                        FoodItemView(food: food, onSelect: {
                            selectedFood = food
                        })
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("Add Food to \(meal.name)")
    }
}

// MARK: - Food Item View

struct FoodItemView: View {
    let food: UserFood
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(food.name)
                        .font(.headline)
                    Text("\(food.calories) kcal")
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Plus Button
                Button(action: onSelect) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity) // Makes it span full width
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
        }
    }
}

// MARK: - Preview

struct FoodSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FoodSearchView(meal: UserMeal(name: "Lunch", foods: []))
        }
    }
}
