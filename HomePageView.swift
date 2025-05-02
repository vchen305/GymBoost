import SwiftUI

struct HomepageView: View {
    @Binding var showHomepage: Bool
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = "Loading..."
    @State private var daily_calories: Int = 0
    @State private var calories_consumed: Int = 0
    @State private var calories_burned: Int = 0
    @State private var calories_needed: Int = 0
    @State private var carbs: Double = 0
    @State private var protein: Double = 0
    @State private var fat: Double = 0

    var body: some View {
        TabView {
            // Home Tab
            NavigationStack {
                ZStack {
                    (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Fixed Header
                        HStack {
                            NavigationLink(destination: ProfileView(showHomepage: $showHomepage)) {
                                Image(systemName: "person.circle")
                                    .font(.title)
                                    .foregroundColor(isDarkMode ? .white : .black)
                            }

                            Text("GymBoost")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(Color.orange)
                                .frame(maxWidth: .infinity, alignment: .center)

                            Spacer().frame(width: 40)
                        }
                        .padding(.horizontal)
                        .padding(.top, 0)
                        .background(
                            (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                                .ignoresSafeArea(edges: .top)
                        )

                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack {
                                    Text("Calories")
                                        .font(.headline)
                                        .foregroundColor(isDarkMode ? .white : .black)

                                    ZStack {
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                                        Circle()
                                            .trim(from: 0, to: CGFloat(calories_needed) / CGFloat(daily_calories == 0 ? 1 : daily_calories))
                                            .stroke(Color.orange, lineWidth: 10)
                                            .rotationEffect(.degrees(-90))
                                        Text("\(calories_needed)\nNeeded")
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
                                    .padding()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(isDarkMode ? Color(UIColor.secondarySystemBackground) : Color.white)
                                )
                                .shadow(radius: 3)
                                .padding(.bottom, 20)

                                VStack {
                                    Text("Nutrients")
                                        .font(.headline)
                                        .foregroundColor(isDarkMode ? .white : .black)

                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Carbs").font(.caption)
                                            Text("\(String(format: "%.2f", carbs)) g").bold()
                                        }
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Fat").font(.caption)
                                            Text("\(String(format: "%.2f", fat)) g").bold()
                                        }
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("Protein").font(.caption)
                                            Text("\(String(format: "%.2f", protein)) g").bold()
                                        }
                                    }
                                    .foregroundColor(isDarkMode ? .white : .black)
                                    .padding()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(isDarkMode ? Color(UIColor.secondarySystemBackground) : Color.white)
                                )
                                .shadow(radius: 3)

                                Image("ducklogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, minHeight: 210, maxHeight: 215)
                                    .clipped()
                                    .cornerRadius(15)
                                    .shadow(radius: 3)
                                    .padding(.horizontal)
                                    .padding(.top, 20)

                                Spacer(minLength: 20)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                fetchUserPreferences()
                fetchCaloriesData()
            }
            .tabItem { Label("Home", systemImage: "house") }

            // Workouts Tab
            NavigationStack {
                WorkoutOptionsView()
            }
            .navigationBarBackButtonHidden(true)
            .tabItem { Label("Workouts", systemImage: "dumbbell") }

            // Nutrition Tab
            NavigationStack {
                NutritionView(showHomepage: $showHomepage)
            }
            .navigationBarBackButtonHidden(true)
            .tabItem { Label("Nutrition", systemImage: "leaf") }

            // AI Chat Tab
            NavigationStack {
                AIChatView(isDarkMode: $isDarkMode)
            }
            .navigationBarBackButtonHidden(true)
            .tabItem { Label("AI Chat", systemImage: "bubble.left.and.bubble.right") }
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserDarkModePreference()
                }
            } catch { }
        }.resume()
    }

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
    }

    private func fetchCaloriesData() {
        guard let url = URL(string: "http://localhost:3000/caloriesData") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            do {
                let decoded = try JSONDecoder().decode(CaloriesData.self, from: data)
                DispatchQueue.main.async {
                    self.daily_calories = decoded.daily_calories
                    self.calories_consumed = decoded.calories_consumed
                    self.calories_burned = decoded.calories_burned
                    self.calories_needed = decoded.calories_needed
                    self.carbs = decoded.carbs
                    self.protein = decoded.protein
                    self.fat = decoded.fat
                }
            } catch { }
        }.resume()
    }
}

struct CaloriesData: Decodable {
    var daily_calories: Int
    var calories_consumed: Int
    var calories_burned: Int
    var calories_needed: Int
    var carbs: Double
    var protein: Double
    var fat: Double

    enum CodingKeys: String, CodingKey {
        case daily_calories, calories_consumed, calories_burned, calories_needed, carbs, protein, fat
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        daily_calories = try container.decode(Int.self, forKey: .daily_calories)
        calories_consumed = try container.decode(Int.self, forKey: .calories_consumed)
        calories_burned = try container.decode(Int.self, forKey: .calories_burned)
        calories_needed = try container.decode(Int.self, forKey: .calories_needed)
        carbs = try Self.decodeNutrientValue(from: container, forKey: .carbs)
        protein = try Self.decodeNutrientValue(from: container, forKey: .protein)
        fat = try Self.decodeNutrientValue(from: container, forKey: .fat)
    }

    private static func decodeNutrientValue(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> Double {
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key), let doubleValue = Double(value) {
            return doubleValue
        }
        throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Expected Double or String for nutrient")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView(showHomepage: .constant(true))
    }
}
