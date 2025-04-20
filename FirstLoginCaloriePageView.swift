    import SwiftUI

    struct FirstLoginCaloriePageView: View {
        @State private var selectedCalories: Int? = nil
        @State private var otherCalories: String = ""
        @State private var errorMessage: String? = nil
        @Binding var showHomepage: Bool
        var isFromSettings: Bool

        @AppStorage("authToken") private var authToken: String = ""
        @State private var isDarkMode: Bool = false
        @State private var username: String = "Loading..."
        
        @Environment(\.presentationMode) var presentationMode

        let calorieOptions = [1000, 2000, 3000, 4000, 5000]

        var body: some View {
            NavigationStack {
                ZStack {
                    (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        Text("Choose your preferred daily calorie needs")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.top, 40)
                            .foregroundColor(isDarkMode ? .white : .black)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(calorieOptions, id: \.self) { calorie in
                                HStack {
                                    Checkbox(isChecked: self.selectedCalories == calorie) {
                                        self.selectedCalories = calorie
                                        self.otherCalories = ""
                                    }
                                    Text("\(calorie) kcal")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                            }

                            HStack {
                                Checkbox(isChecked: selectedCalories == -1) {
                                    selectedCalories = selectedCalories == -1 ? nil : -1
                                }
                                Text("Other")
                                    .foregroundColor(isDarkMode ? .white : .black)
                            }
                        }
                        .padding()

                        if selectedCalories == -1 {
                            TextField("Enter your calories", text: $otherCalories)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(isDarkMode ? Color.gray.opacity(0.3) : Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .onChange(of: otherCalories) { oldValue, newValue in
                                    otherCalories = newValue.filter { "0123456789".contains($0) }
                                }
                        }

                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .padding(.top, 10)
                        }

                        VStack {
                            Text("Selected Calorie Options:")
                                .font(.headline)
                                .foregroundColor(isDarkMode ? .white : .black)

                            if let selectedCalories = selectedCalories {
                                if selectedCalories != -1 {
                                    Text("\(selectedCalories) kcal")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                } else if !otherCalories.isEmpty {
                                    Text("Other: \(otherCalories) kcal")
                                        .foregroundColor(isDarkMode ? .white : .black)
                                }
                            }
                        }
                        .padding()

                        Button(action: {
                            if selectedCalories == nil {
                                errorMessage = "Please select a calorie option"
                            } else if selectedCalories == -1 {
                                if let number = Int(otherCalories), number >= 1000, number <= 10_000 {
                                    errorMessage = nil
                                    handleDismiss()
                                } else {
                                    errorMessage = "Please enter a calorie value between 1000 and 10,000."
                                }
                            } else {
                                errorMessage = nil
                                handleDismiss()
                            }
                        }) {
                            Text("Confirm")
                                .fontWeight(.bold)
                                .frame(width: 200, height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.top, 20)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    fetchUserPreferences()
                }
            }
        }

        private func handleDismiss() {
            let selectedValue: Int
            // Check if "selectedCalories" is -1, then use "otherCalories", otherwise use the selected value
            if selectedCalories == -1 {
                selectedValue = Int(otherCalories) ?? 0
            } else {
                selectedValue = selectedCalories ?? 0
            }

            // Ensure the calorie value is valid (>= 1000)
            guard selectedValue >= 1000 else {
                errorMessage = "Invalid calorie value"
                return
            }

        
            let caloriesNeeded = selectedValue

            // Define the URL for the API endpoint
            guard let url = URL(string: "http://localhost:3000/update-calories") else {
                print("Invalid URL")
                return
            }

            // Create the URLRequest
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(authToken, forHTTPHeaderField: "Authorization")

            // Set the body data with both daily_calories and calories_needed
            let body: [String: Any] = [
                "daily_calories": selectedValue,
                "calories_needed": caloriesNeeded
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                print("Failed to encode calorie data")
                return
            }

            // Perform the network request to send the data
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error saving daily calories: \(error)")
                    return
                }

                DispatchQueue.main.async {
                    if isFromSettings {
                        // Dismiss if coming from settings page
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        // Navigate to homepage if necessary
                        showHomepage = true
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }.resume()
        }

        private func fetchUserPreferences() {
            guard let url = URL(string: "http://localhost:3000/profile") else {
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(authToken, forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let _ = error { return }
                guard let data = data else { return }

                do {
                    let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                    DispatchQueue.main.async {
                        self.username = decodedResponse.username
                        loadUserDarkModePreference()
                    }
                } catch {
                    print("Error decoding user data")
                }
            }.resume()
        }

        private func loadUserDarkModePreference() {
            let userKey = "isDarkMode_\(username)"
            isDarkMode = UserDefaults.standard.bool(forKey: userKey)
        }
    }

    struct Checkbox: View {
        var isChecked: Bool
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Rectangle()
                        .fill(isChecked ? Color.blue : Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(
                            isChecked ? Text("✓")
                                .foregroundColor(.white)
                                .font(.system(size: 18)) : nil
                        )
                        .border(Color.black, width: 2)
                }
            }
        }
    }


    struct FirstLoginCaloriePageView_Previews: PreviewProvider {
        static var previews: some View {
            FirstLoginCaloriePageView(showHomepage: .constant(false), isFromSettings: false)
        }
    }
