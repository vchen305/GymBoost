import SwiftUI

struct NutritionView: View {
    @State private var caloriesConsumed: Int = 2100
    @State private var caloriesBurned: Int = 300
    @State private var dailyGoal: Int = 2750
    @State private var meals: [Meal] = [
        Meal(name: "Breakfast", foods: []),
        Meal(name: "Lunch", foods: []),
        Meal(name: "Dinner", foods: [])
    ]
    @State private var isDarkMode: Bool = false

    var body: some View {
        VStack {
            
            HStack {
                Text("GymBoost")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.orange)
                    .padding(.top, 1)
                    .padding(.leading, 117)

                Spacer()
            }
            .padding(.horizontal)
            // Calories Summary
            VStack {
                
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(caloriesConsumed) / CGFloat(dailyGoal))
                        .stroke(Color.orange, lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                    Text("\(dailyGoal - caloriesConsumed)\nNeeded")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .frame(width: 100, height: 100)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Daily Goal").font(.caption)
                        Text("\(dailyGoal)").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Consumed").font(.caption)
                        Text("\(caloriesConsumed)").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Burned").font(.caption)
                        Text("\(caloriesBurned)").bold()
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
            .shadow(radius: 3)

            // Meal Widgets
            ScrollView {
                ForEach(meals) { meal in
                    MealWidget(meal: meal, isDarkMode: isDarkMode)
                }
            }
            .padding(.horizontal)

            Spacer()
            
            HStack {
                BottomTabItem(icon: "house", label: "Home", isDarkMode: isDarkMode)
                BottomTabItem(icon: "dumbbell", label: "Workouts", isDarkMode: isDarkMode)
                BottomTabItem(icon: "leaf", label: "Nutrition", highlighted: true, isDarkMode: isDarkMode)
                BottomTabItem(icon: "line.3.horizontal", label: "More", isDarkMode: isDarkMode)
            }
            .frame(height: 60)
            .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
            .shadow(radius: isDarkMode ? 0 : 2)
        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
        .navigationBarTitle("Nutrition", displayMode: .inline)
        .onAppear {
            fetchNutritionData()
        }
    }

    private func fetchNutritionData() {
        // Fetch calorie and meal data from your backend
        // Example: Make a GET request to http://localhost:3000/nutrition
    }
}

struct Meal: Identifiable {
    let id = UUID()
    let name: String
    var foods: [Food]
}

struct Food: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
}

struct MealWidget: View {
    let meal: Meal
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                Spacer()
                NavigationLink(destination: AddFoodView(meal: meal)) {
                    Text("Add Food")
                        .foregroundColor(.blue)
                }
            }

            ForEach(meal.foods) { food in
                HStack {
                    Text(food.name)
                        .foregroundColor(isDarkMode ? .white : .black)
                    Spacer()
                    Text("\(food.calories) kcal")
                        .foregroundColor(.gray)
                }
            }

            if meal.foods.isEmpty {
                Text("No foods added yet.")
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
        .shadow(radius: 3)
        .padding(.vertical, 8)
    }
}

struct AddFoodView: View {
    let meal: Meal
    @State private var selectedFood: Food?

    // Explicit initializer
    init(meal: Meal) {
        self.meal = meal
    }

    var body: some View {
        List {
            ForEach(foodOptions) { food in
                Button(action: {
                    selectedFood = food
                }) {
                    HStack {
                        Text(food.name)
                        Spacer()
                        Text("\(food.calories) kcal")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .navigationTitle("Add Food")
    }

    private var foodOptions: [Food] = [
        Food(name: "Scrambled Eggs", calories: 140),
        Food(name: "Toast", calories: 75),
        Food(name: "Salad", calories: 100),
        Food(name: "Chicken Breast", calories: 165),
        Food(name: "Rice", calories: 200)
    ]
}

struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionView()
    }
}
