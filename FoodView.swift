import SwiftUI

struct FoodSearchView: View {
    @Binding var isDarkMode: Bool
    @Binding var meal: Meal
    var onFoodAdded: (Food) -> Void

    @State private var searchText: String = ""
    @State private var foodOptions: [Food] = []
    @State private var sortBy: String = "name"
    @State private var sortOrder: String = "asc"
    @AppStorage("authToken") private var authToken: String = ""

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                .ignoresSafeArea()

            VStack(spacing: 10) {
                // Custom placeholder text for search
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("Search for food")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.leading, 16)
                    }
                    TextField("", text: $searchText)
                        .padding(12)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .onChange(of: searchText) { _ in
                            fetchFoodFromBackend()
                        }
                }
                .background(isDarkMode ? Color.black.opacity(0.2) : Color.white)
                .cornerRadius(12)
                .padding(.horizontal)

                // Sort controls
                HStack {
                    Picker("Sort by", selection: $sortBy) {
                        Text("Name").tag("name")
                        Text("Calories").tag("calories")
                    }
                    .pickerStyle(.segmented)
                    .background(isDarkMode ? Color.black.opacity(0.2) : Color.white)
                    .cornerRadius(8)
                    .onChange(of: sortBy) { _ in fetchFoodFromBackend() }

                    Button(action: {
                        sortOrder = sortOrder == "asc" ? "desc" : "asc"
                        fetchFoodFromBackend()
                    }) {
                        Image(systemName: sortOrder == "asc" ? "arrow.up" : "arrow.down")
                            .foregroundColor(isDarkMode ? .white : .blue)
                    }
                }
                .padding(.horizontal)

                // Results list
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(foodOptions) { food in
                            FoodItemView(food: food, isDarkMode: isDarkMode) { scaledFood in
                                onFoodAdded(scaledFood)
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationTitle("Add Food to \(meal.name)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fetchFoodFromBackend() }
    }

    private func fetchFoodFromBackend() {
        let encoded = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "http://localhost:3000/api/foods?search=\(encoded)&sort=\(sortBy)&order=\(sortOrder)") else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data,
               let decoded = try? JSONDecoder().decode(FoodResponse.self, from: data) {
                DispatchQueue.main.async { foodOptions = decoded.data }
            }
        }.resume()
    }
}

struct FoodItemView: View {
    let food: Food
    let isDarkMode: Bool
    let onSelect: (Food) -> Void

    @State private var selectedServingSize: String
    @State private var quantity: Double
    @AppStorage("authToken") private var authToken: String = ""

    private let servingOptions: [String] = ["g", "kg", "oz", "ml", "tbsp", "cup", "slice"]

    init(food: Food, isDarkMode: Bool, onSelect: @escaping (Food) -> Void) {
        self.food = food
        self.isDarkMode = isDarkMode
        self.onSelect = onSelect
        let defaultUnit = food.nutrients.first?.unit ?? "g"
        let defaultAmount = food.nutrients.first?.amount ?? 100
        _selectedServingSize = State(initialValue: defaultUnit.lowercased())
        _quantity = State(initialValue: defaultAmount)
    }

    var body: some View {
        let base = food.nutrients.first
        let baseAmount = base?.amount ?? 100
        let multiplier = getMultiplier(for: selectedServingSize, baseUnit: base?.unit ?? "g")
        let adjusted = (quantity * multiplier) / baseAmount
        let calories = Int(Double(food.calories) * adjusted)
        let proteinVal = getNutrientValue(for: "protein", multiplier: adjusted)
        let fatVal = getNutrientValue(for: "total lipid (fat)", multiplier: adjusted)
        let carbVal = getNutrientValue(for: "carbohydrate, by difference", multiplier: adjusted)

        VStack(alignment: .leading, spacing: 8) {
            Text(food.name)
                .font(.headline)
                .foregroundColor(isDarkMode ? .white : .primary)

            Text("\(calories) kcal")
                .foregroundColor(.gray)

            if let p = proteinVal {
                Text("Protein: \(String(format: "%.1f", p)) g")
                    .foregroundColor(isDarkMode ? .white : .primary)
            }
            if let f = fatVal {
                Text("Fat: \(String(format: "%.1f", f)) g")
                    .foregroundColor(isDarkMode ? .white : .primary)
            }
            if let c = carbVal {
                Text("Carbs: \(String(format: "%.1f", c)) g")
                    .foregroundColor(isDarkMode ? .white : .primary)
            }

            HStack {
                Text("Serving:")
                    .foregroundColor(isDarkMode ? .white : .primary)

                TextField("Qty", value: $quantity, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(isDarkMode ? Color.black.opacity(0.2) : Color.white)

                Picker("Unit", selection: $selectedServingSize) {
                    ForEach(servingOptions, id: \.self) { size in Text(size).tag(size) }
                }
                .pickerStyle(MenuPickerStyle())
            }

            HStack {
                Spacer()
                Button(action: {
                    var newFood = food
                    newFood.calories = calories
                    newFood.nutrients = newFood.nutrients.map { nut in
                        var m = nut
                        if m.nutrient_name.lowercased() == "protein" { m.nutrient_value = proteinVal ?? 0 }
                        if m.nutrient_name.lowercased() == "total lipid (fat)" { m.nutrient_value = fatVal ?? 0 }
                        if m.nutrient_name.lowercased() == "carbohydrate, by difference" { m.nutrient_value = carbVal ?? 0 }
                        return m
                    }
                    onSelect(newFood)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
    }

    private func getMultiplier(for selectedSize: String, baseUnit: String) -> Double {
        let table: [String: Double] = ["g":1, "kg":1000, "oz":28.35, "ml":1, "tbsp":15, "cup":240, "slice":30]
        return (table[selectedSize.lowercased()] ?? 1) / (table[baseUnit.lowercased()] ?? 1)
    }

    private func getNutrientValue(for nutrientName: String, multiplier: Double) -> Double? {
        guard let nut = food.nutrients.first(where: { $0.nutrient_name.lowercased() == nutrientName.lowercased() }) else { return nil }
        return nut.nutrient_value * multiplier
    }
}

struct FoodResponse: Codable { let data: [Food] }
