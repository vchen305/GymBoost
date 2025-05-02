import SwiftUI

struct NutritionView: View {
    @State private var isDarkMode: Bool = false
    @Binding var showHomepage: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = "Loading..."
    @State private var daily_calories: Int = 0
    @State private var calories_consumed: Int = 0
    @State private var calories_burned: Int = 0
    @State private var needed_calories: Int = 0

    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var protein: Double = 0

    @State private var meals: [Meal] = [
        Meal(name: "Breakfast", foods: []),
        Meal(name: "Lunch", foods: []),
        Meal(name: "Dinner", foods: [])
    ]

    private func updateCalories() {
        let allFoods = meals.flatMap { $0.foods }
        calories_consumed = allFoods.reduce(0) { $0 + $1.calories }
        needed_calories = max(0, daily_calories - calories_consumed)

        var carbsTotal: Double = 0
        var fatTotal: Double = 0
        var proteinTotal: Double = 0
        for food in allFoods {
            for nut in food.nutrients {
                let name = nut.nutrient_name.lowercased()
                if name.contains("carb") {
                    carbsTotal += nut.nutrient_value
                } else if name.contains("fat") {
                    fatTotal += nut.nutrient_value
                } else if name.contains("protein") {
                    proteinTotal += nut.nutrient_value
                }
            }
        }
        carbs = carbsTotal
        fat = fatTotal
        protein = proteinTotal
        saveMealsToUserDefaults()
    }

    private func resetServerCalories() {
        guard let url = URL(string: "http://localhost:3000/update-calories") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(authToken, forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "daily_calories": daily_calories,
            "calories_needed": daily_calories
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req).resume()
    }

    private func sendNutritionUpdate() {
        guard let url = URL(string: "http://localhost:3000/update-nutrition") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "calories_consumed": calories_consumed,
            "carbs": carbs,
            "fat": fat,
            "protein": protein
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request).resume()
    }

    private func saveMealsToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(meals) {
            UserDefaults.standard.set(encoded, forKey: "savedMeals_\(username)")
        }
    }

    private func loadMealsFromUserDefaults() {
        if let savedData = UserDefaults.standard.data(forKey: "savedMeals_\(username)"),
           let decodedMeals = try? JSONDecoder().decode([Meal].self, from: savedData) {
            meals = decodedMeals
        }
    }

    private func fetchCaloriesData() {
        guard let url = URL(string: "http://localhost:3000/caloriesData") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let resp = try JSONDecoder().decode(CaloriesData.self, from: data)
                DispatchQueue.main.async {
                    daily_calories = resp.daily_calories
                    calories_consumed = resp.calories_consumed
                    calories_burned = resp.calories_burned
                    needed_calories = resp.calories_needed
                    carbs = resp.carbs
                    fat = resp.fat
                    protein = resp.protein
                }
            } catch { print(error) }
        }.resume()
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let profile = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    username = profile.username
                    loadUserDarkModePreference()
                }
            } catch { print(error) }
        }.resume()
    }

    private func loadUserDarkModePreference() {
        let key = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: key)
        loadMealsFromUserDefaults()
    }

    var body: some View {
        VStack {
            HStack {
                Text("GymBoost")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.orange)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 10)

            // Calories Summary
            VStack {
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(needed_calories) / CGFloat(daily_calories == 0 ? 1 : daily_calories))
                        .stroke(Color.orange, lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                    Text("\(needed_calories)\nNeeded")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .frame(width: 100, height: 100)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Daily Goal").font(.caption)
                        Text("\(daily_calories)").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Consumed").font(.caption)
                        Text("\(calories_consumed)").bold()
                    }
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.bottom, 4)

                Divider().padding(.vertical, 4)

                HStack(spacing: 20) {
                    VStack {
                        Text("Carbs").font(.caption)
                        Text("\(Int(carbs))g").bold()
                    }
                    VStack {
                        Text("Fat").font(.caption)
                        Text("\(Int(fat))g").bold()
                    }
                    VStack {
                        Text("Protein").font(.caption)
                        Text("\(Int(protein))g").bold()
                    }
                }
                .foregroundColor(isDarkMode ? .white : .black)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isDarkMode ? Color(UIColor.secondarySystemBackground) : Color.white)
            )
            .shadow(radius: 3)

            ScrollView {
                ForEach($meals, id: \.id) { $meal in
                    MealWidget(
                        meal: $meal,
                        isDarkMode: isDarkMode,
                        addFoodAction: {
                            NavigationLink(
                                destination: FoodSearchView(isDarkMode: $isDarkMode, meal: $meal, onFoodAdded: { food in
                                    meal.foods.append(food)
                                    updateCalories()
                                    sendNutritionUpdate()
                                    saveMealsToUserDefaults()
                                })
                            ) {
                                Text("Add Food").foregroundColor(.blue)
                            }
                        },
                        clearAction: {
                            meal.foods.removeAll()
                            updateCalories()
                            saveMealsToUserDefaults()
                            resetServerCalories()
                            sendNutritionUpdate()
                        }
                    )
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
        .onAppear {
            fetchUserPreferences()
            fetchCaloriesData()
        }
    }
}

// MARK: Supporting Types

struct Food: Identifiable, Codable {
    var id = UUID()
    var food_id: Int
    var name: String
    var calories: Int
    var nutrients: [FoodNutrient]

    enum CodingKeys: String, CodingKey {
        case food_id = "id"
        case name, calories, nutrients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        food_id = try container.decode(Int.self, forKey: .food_id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        nutrients = try container.decode([FoodNutrient].self, forKey: .nutrients)
        id = UUID()
    }

    init(food_id: Int, name: String, calories: Int, nutrients: [FoodNutrient]) {
        self.food_id = food_id
        self.name = name
        self.calories = calories
        self.nutrients = nutrients
        id = UUID()
    }
}

struct FoodNutrient: Codable, Identifiable {
    let id: Int
    let food_id: Int
    let serving_size_description: String
    let amount: Double
    let unit: String
    var nutrient_name: String
    var nutrient_value: Double
    let calories: Double
}

struct Meal: Identifiable, Codable {
    let id: UUID
    let name: String
    var foods: [Food]

    init(id: UUID = UUID(), name: String, foods: [Food]) {
        self.id = id
        self.name = name
        self.foods = foods
    }
}

struct MealWidget: View {
    @Binding var meal: Meal
    let isDarkMode: Bool
    let addFoodAction: () -> NavigationLink<Text, FoodSearchView>
    let clearAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                Spacer()
                Button("Clear") { clearAction() }
                    .foregroundColor(.red)
                    .padding(.trailing, 8)
                addFoodAction()
            }

            if meal.foods.isEmpty {
                Text("No foods added yet.")
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                ForEach(meal.foods) { food in
                    HStack {
                        Text(food.name)
                            .foregroundColor(isDarkMode ? .white : .black)
                        Spacer()
                        Text("\(food.calories) kcal")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color(UIColor.secondarySystemBackground) : Color.white)
        )
        .shadow(radius: 3)
        .padding(.vertical, 8)
    }
}

struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { NutritionView(showHomepage: .constant(true)) }
    }
}
