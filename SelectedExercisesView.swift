import SwiftUI

struct SelectedExercisesView: View {
    @State var selectedExercises: [Exercise]
    @State private var selectedDay = "Monday"
    @State private var isWorkoutSaved = false

    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = "Loading..."

    let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var totalSets: Int {
        selectedExercises.compactMap { $0.sets ?? 0 }.reduce(0, +)
    }

    var totalReps: Int {
        selectedExercises.compactMap { $0.reps ?? 0 }.reduce(0, +)
    }

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black.opacity(0.8) : Color.white)
                .ignoresSafeArea()

            VStack {
                // Day Picker
                Picker("Select Day", selection: $selectedDay) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day).tag(day)
                      
                            
                    }
                  
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.clear)

                List {
                    ForEach($selectedExercises) { $exercise in
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .font(.headline)
                                .foregroundColor(isDarkMode ? .white : .black)
                                .padding(.vertical, 8)

                            HStack {
                                Text("Sets:")
                                    .font(.subheadline)
                                    .foregroundColor(isDarkMode ? .white : .black)

                                TextField("Sets", value: $exercise.sets, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                            }

                            HStack {
                                Text("Reps:")
                                    .font(.subheadline)
                                    .foregroundColor(isDarkMode ? .white : .black)

                                TextField("Reps", value: $exercise.reps, format: .number)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .frame(width: 80)
                            }
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(isDarkMode ? Color.black.opacity(0.3) : Color.gray.opacity(0.2))
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)

                // Total sets and reps
                HStack {
                    Text("Total Sets and Reps")
                        .font(.headline)
                    Spacer()
                    Text("\(totalSets) sets, \(totalReps) reps")
                        .font(.headline)
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding()
                .background(isDarkMode ? Color.gray.opacity(0.3) : Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding()

                // Save Button
                Button(action: {
                    saveAllWorkouts()
                }) {
                    Text("Save Workouts")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                // Navigation to WorkoutList after saving
                NavigationLink(destination: WorkoutList(), isActive: $isWorkoutSaved) {
                    EmptyView()
                }
            }
            .padding()
        }
        
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Selected Exercises")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        }
     
        .onAppear {
            fetchUserPreferences()
        }
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let decoded = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decoded.username
                    loadUserDarkModePreference()
                }
            } catch {
                print("Error decoding user profile.")
            }
        }.resume()
    }

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
        print("Dark mode preference loaded: \(isDarkMode ? "Enabled" : "Disabled")")
    }

    private func saveAllWorkouts() {
        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not found.")
            return
        }

        let group = DispatchGroup()

        for exercise in selectedExercises {
            guard let sets = exercise.sets, let reps = exercise.reps else {
                print("Sets or reps not entered for \(exercise.name)")
                continue
            }

            let workoutData: [String: Any] = [
                "name": exercise.name,
                "sets": sets,
                "reps": reps,
                "day": selectedDay
            ]

            guard let url = URL(string: "http://localhost:3000/save-workout") else { continue }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(authToken, forHTTPHeaderField: "Authorization")

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: workoutData)
            } catch {
                print("Error encoding data: \(error)")
                continue
            }

            group.enter()
            URLSession.shared.dataTask(with: request) { data, response, error in
                defer { group.leave() }

                if let error = error {
                    print("Error saving workout \(exercise.name): \(error)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("Response for \(exercise.name): \(httpResponse.statusCode)")
                }
            }.resume()
        }

        group.notify(queue: .main) {
            isWorkoutSaved = true
        }
    }
}


struct SelectedExercisesView_Previews: PreviewProvider {
    static var previews: some View {
        SelectedExercisesView(selectedExercises: [])
    }
}
