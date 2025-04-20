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

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error:", error)
                return
            }

            guard let data = data else { return }

            do {
                let decodedResponse = try JSONDecoder().decode(CaloriesData.self, from: data)
                DispatchQueue.main.async {
                    self.daily_calories = decodedResponse.daily_calories
                    self.calories_consumed = decodedResponse.calories_consumed
                    self.calories_burned = decodedResponse.calories_burned
                    self.needed_calories = decodedResponse.calories_needed
                    self.carbs = decodedResponse.carbs
                    self.fat = decodedResponse.fat
                    self.protein = decodedResponse.protein
                }
            } catch {
                print("Decoding error:", error)
            }
        }.resume()
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { return }
            guard let data = data else { return }

            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserDarkModePreference()
                }
            } catch {}
        }.resume()
    }

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
        loadMealsFromUserDefaults() // Load meals after getting username
    }

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
                        .trim(from: 0, to: CGFloat(needed_calories) / CGFloat(daily_calories))
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
            .background(RoundedRectangle(cornerRadius: 15).fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
            .shadow(radius: 3)

            // Meal Widgets
            ScrollView {
                ForEach($meals) { $meal in
                    MealWidget(meal: $meal, isDarkMode: isDarkMode) {
                        NavigationLink(destination: FoodSearchView(meal: $meal, onFoodAdded: { food in
                            meal.foods.append(food)
                            saveMealsToUserDefaults() // Save meals after food is added
                        })) {
                            Text("Add Food")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                NavigationLink(destination: HomepageView(showHomepage: $showHomepage)) {
                    BottomTabItem(icon: "house", label: "Home", isDarkMode: isDarkMode)
                        .offset(y: 4)
                }

                NavigationLink(destination: WorkoutOptionsView()) {
                    BottomTabItem(icon: "dumbbell", label: "Workouts", isDarkMode: isDarkMode)
                        .offset(y: 4)
                }

                BottomTabItem(icon: "leaf", label: "Nutrition", highlighted: true, isDarkMode: isDarkMode)
                    .offset(y: 4)

                BottomTabItem(icon: "line.3.horizontal", label: "More", isDarkMode: isDarkMode)
                    .offset(y: 4)
            }
            .frame(height: 60)
            .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
            .shadow(radius: isDarkMode ? 0 : 2)
            .padding(.bottom, 0)
        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
        .onAppear {
            fetchUserPreferences()
            fetchCaloriesData()
        }
    }
}


struct Food: Identifiable, Codable {
    var id = UUID()
    var food_id: Int
    var name: String
    var calories: Int
    var nutrients: [FoodNutrient]

    enum CodingKeys: String, CodingKey {
        case food_id = "id"
        case name
        case calories
        case nutrients
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.food_id = try container.decode(Int.self, forKey: .food_id)
        self.name = try container.decode(String.self, forKey: .name)
        self.calories = try container.decode(Int.self, forKey: .calories)
        self.nutrients = try container.decode([FoodNutrient].self, forKey: .nutrients)
        self.id = UUID()
    }

    init(food_id: Int, name: String, calories: Int, nutrients: [FoodNutrient]) {
        self.id = UUID()
        self.food_id = food_id
        self.name = name
        self.calories = calories
        self.nutrients = nutrients
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
    var addFoodAction: () -> NavigationLink<Text, FoodSearchView>

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(meal.name)
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                Spacer()
                addFoodAction()
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



struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionView(showHomepage: .constant(true))
        }
    }
}
