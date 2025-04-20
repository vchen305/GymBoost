import SwiftUI

struct FoodSearchView: View {
    @Binding var meal: Meal
    var onFoodAdded: (Food) -> Void

    @State private var searchText: String = ""
    @State private var foodOptions: [Food] = []
    @State private var sortBy: String = "name"
    @State private var sortOrder: String = "asc"
    @AppStorage("authToken") private var authToken: String = ""

    @Environment(\.presentationMode) var presentationMode

    let commonServingSizes = ["g", "kg", "ml", "cup", "tbsp", "oz", "slice"]

    var body: some View {
        VStack(spacing: 10) {
            TextField("Search for food", text: $searchText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .onChange(of: searchText) { fetchFoodFromBackend() }

            HStack {
                Picker("Sort by", selection: $sortBy) {
                    Text("Name").tag("name")
                    Text("Calories").tag("calories")
                }
                .pickerStyle(.segmented)
                .onChange(of: sortBy) { fetchFoodFromBackend() }

                Button(action: {
                    sortOrder = (sortOrder == "asc") ? "desc" : "asc"
                    fetchFoodFromBackend()
                }) {
                    Image(systemName: sortOrder == "asc" ? "arrow.up" : "arrow.down")
                }
            }
            .padding(.horizontal)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(foodOptions) { food in
                        FoodItemView(food: food) { scaledFood in
                            onFoodAdded(scaledFood)
                         
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .navigationTitle("Add Food to \(meal.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchFoodFromBackend()
        }
    }

    private func fetchFoodFromBackend() {
        let encodedSearch = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "http://localhost:3000/api/foods?search=\(encodedSearch)&sort=\(sortBy)&order=\(sortOrder)"

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(FoodResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.foodOptions = decoded.data
                    }
                } catch {
                    print("Decoding error:", error)
                }
            } else if let error = error {
                print("Fetch error:", error)
            }
        }.resume()
    }

   
}

struct FoodResponse: Codable {
    let data: [Food]
}

struct FoodItemView: View {
    let food: Food
    let onSelect: (Food) -> Void

    @State private var selectedServingSize: String
    @State private var quantity: Double
    @AppStorage("authToken") private var authToken: String = ""

    let servingOptions: [String] = ["g", "kg", "oz", "ml", "tbsp", "cup", "slice"]

    init(food: Food, onSelect: @escaping (Food) -> Void) {
        self.food = food
        self.onSelect = onSelect

        let defaultUnit = food.nutrients.first?.unit ?? "g"
        let defaultAmount = food.nutrients.first?.amount ?? 100

        _selectedServingSize = State(initialValue: defaultUnit.lowercased())
        _quantity = State(initialValue: defaultAmount)
    }

    var body: some View {
        let baseAmount = food.nutrients.first?.amount ?? 100
        let baseUnit = food.nutrients.first?.unit ?? "g"
        let multiplier = getMultiplier(for: selectedServingSize, baseUnit: baseUnit)
        let adjustedMultiplier = (quantity * multiplier) / baseAmount
        let scaledCalories = Int(Double(food.calories) * adjustedMultiplier)

        // Retrieve and scale nutrients from the nutrients array
        let scaledProtein = getNutrientValue(for: "protein", multiplier: adjustedMultiplier)
        let scaledFat = getNutrientValue(for: "total lipid (fat)", multiplier: adjustedMultiplier)
        let scaledCarbs = getNutrientValue(for: "carbohydrate, by difference", multiplier: adjustedMultiplier)

        VStack(alignment: .leading, spacing: 8) {
            Text(food.name)
                .font(.headline)

            Text("\(scaledCalories) kcal")
                .foregroundColor(.gray)

            if let protein = scaledProtein {
                Text("Protein: \(String(format: "%.1f", protein)) g")
            }

            if let fat = scaledFat {
                Text("Fat: \(String(format: "%.1f", fat)) g")
            }

            if let carb = scaledCarbs {
                Text("Carbs: \(String(format: "%.1f", carb)) g")
            }

            Text("Serving: \(String(format: "%.1f", quantity)) \(selectedServingSize)")

            HStack {
                Text("Custom Amount:")
                TextField("Qty", value: $quantity, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("Unit", selection: $selectedServingSize) {
                    ForEach(servingOptions, id: \.self) { size in
                        Text(size).tag(size)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }

            HStack {
                Spacer()
                Button(action: {
                    var scaledFood = food
                    scaledFood.calories = scaledCalories
                    
                    // Update the nutrients with the scaled values
                    scaledFood.nutrients = scaledFood.nutrients.map { nutrient in
                        var scaledNutrient = nutrient
                        if scaledNutrient.nutrient_name.lowercased() == "protein" {
                            scaledNutrient.nutrient_value = scaledProtein ?? 0
                        }
                        if scaledNutrient.nutrient_name.lowercased() == "total lipid (fat)" {
                            scaledNutrient.nutrient_value = scaledFat ?? 0
                        }
                        if scaledNutrient.nutrient_name.lowercased() == "carbohydrate, by difference" {
                            scaledNutrient.nutrient_value = scaledCarbs ?? 0
                        }
                        return scaledNutrient
                    }
                    
                    onSelect(scaledFood)

               
                    updateCaloriesNeeded(scaledFood.calories, scaledProtein: scaledProtein, scaledFat: scaledFat, scaledCarbs: scaledCarbs)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
    }

    private func getMultiplier(for selectedSize: String, baseUnit: String) -> Double {
        let conversionTable: [String: Double] = [
            "g": 1.0, "kg": 1000.0, "oz": 28.35,
            "ml": 1.0, "tbsp": 15.0, "cup": 240.0, "slice": 30.0
        ]

        let cleanSelected = selectedSize.lowercased().trimmingCharacters(in: .whitespaces)
        let cleanBase = baseUnit.lowercased().trimmingCharacters(in: .whitespaces)

        guard let selectedVal = conversionTable[cleanSelected],
              let baseVal = conversionTable[cleanBase] else {
            return 1.0
        }

        return selectedVal / baseVal
    }

    // Function to get scaled nutrient value for a given nutrient name
    private func getNutrientValue(for nutrientName: String, multiplier: Double) -> Double? {
        guard let nutrient = food.nutrients.first(where: { $0.nutrient_name.lowercased() == nutrientName.lowercased() }) else {
            return nil
        }
        return nutrient.nutrient_value * multiplier
    }
    
    private func updateCaloriesNeeded(_ foodCalories: Int, scaledProtein: Double?, scaledFat: Double?, scaledCarbs: Double?) {
        guard let url = URL(string: "http://localhost:3000/update-calories-needed") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        // Include calories, protein, fat, and carbs in the request body
        let body: [String: Any] = [
            "food_calories": foodCalories,
            "protein": scaledProtein ?? 0,  // Default to 0 if nil
            "fat": scaledFat ?? 0,          // Default to 0 if nil
            "carbs": scaledCarbs ?? 0       // Default to 0 if nil
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Failed to encode calorie data")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating calories_needed: \(error)")
                return
            }

            DispatchQueue.main.async {
            
            }
        }.resume()
    }
}
