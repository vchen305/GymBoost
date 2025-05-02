import SwiftUI

// Exercise Model
struct Exercise: Codable, Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let muscle: String
    let difficulty: String
    let instructions: String
    var sets: Int?
    var reps: Int?
}

struct ExerciseView: View {
    let workoutType: String

    @State private var exercises: [Exercise] = []
    @State private var isLoading = true
    @State private var expandedGroup: String? = nil
    @State private var expandedExerciseId: UUID? = nil
    @State private var selectedExerciseIDs: Set<UUID> = []

    @State private var username: String = "Loading..."
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""

    var muscleGroups: [String] {
        switch workoutType {
        case "Leg Workout": return ["hamstrings", "glutes", "calves", "quadriceps"]
        case "Chest Workout": return ["chest"]
        case "Arms Workout": return ["biceps", "triceps", "forearms"]
        case "Back Workout": return ["lats", "lower_back", "middle_back", "traps"]
        case "Shoulder Workout": return ["traps"]
        default: return []
        }
    }

    var selectedExercises: [Exercise] {
        exercises.filter { selectedExerciseIDs.contains($0.id) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                (isDarkMode ? Color.black.opacity(0.8) : Color.white).ignoresSafeArea()

                VStack {
                    ScrollView {
                        VStack {
                            if isLoading {
                                ProgressView("Loading Exercises...")
                                    .padding(.top, 30)
                            } else if exercises.isEmpty {
                                Text("No exercises found.")
                                    .foregroundColor(.gray)
                                    .padding(.top, 20)
                            } else {
                                ForEach(muscleGroups, id: \.self) { muscleGroup in
                                    VStack(spacing: 0) {
                                        Button(action: {
                                            withAnimation {
                                                expandedGroup = (expandedGroup == muscleGroup) ? nil : muscleGroup
                                            }
                                        }) {
                                            Text("\(muscleGroup.capitalized) Exercises")
                                                .font(.title2)
                                                .bold()
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .background(isDarkMode ? Color.blue.opacity(0.3) : Color.blue.opacity(0.2))
                                                .foregroundColor(isDarkMode ? .white : .blue)
                                                .cornerRadius(10)
                                        }

                                        if expandedGroup == muscleGroup {
                                            VStack(spacing: 10) {
                                                ForEach(Array(exercises.filter { $0.muscle == muscleGroup }.enumerated()), id: \.element.id) { index, exercise in
                                                    let isSelected = selectedExerciseIDs.contains(exercise.id)

                                                    VStack(alignment: .leading, spacing: 10) {
                                                        HStack {
                                                            Text(exercise.name)
                                                                .font(.title2)
                                                                .bold()
                                                                .foregroundColor(isDarkMode ? .white : .black)
                                                            Spacer()
                                                            if isSelected {
                                                                Image(systemName: "checkmark.circle.fill")
                                                                    .foregroundColor(.green)
                                                            }
                                                        }

                                                        Text("Difficulty: \(exercise.difficulty.capitalized)")
                                                            .font(.subheadline)
                                                            .foregroundColor(.gray)

                                                        if expandedExerciseId == exercise.id {
                                                            Divider()
                                                            Text(exercise.instructions)
                                                                .font(.body)
                                                                .foregroundColor(isDarkMode ? .white.opacity(0.8) : .gray)
                                                        }

                                                        Button(action: {
                                                            withAnimation {
                                                                expandedExerciseId = (expandedExerciseId == exercise.id) ? nil : exercise.id
                                                            }
                                                        }) {
                                                            Text(expandedExerciseId == exercise.id ? "Show Less" : "Show More")
                                                                .font(.subheadline)
                                                                .foregroundColor(.blue)
                                                        }
                                                    }
                                                    .padding()
                                                    .background(isSelected ? Color.green.opacity(0.2) : (isDarkMode ? Color.black.opacity(0.2) : Color.white))
                                                    .cornerRadius(12)
                                                    .shadow(color: isDarkMode ? .clear : .gray.opacity(0.2), radius: 3)
                                                    .onTapGesture {
                                                        withAnimation {
                                                            if isSelected {
                                                                selectedExerciseIDs.remove(exercise.id)
                                                            } else {
                                                                selectedExerciseIDs.insert(exercise.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.horizontal)
                                            .padding(.top,20)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 10)
                                }
                            }
                        }
                        .padding(.bottom, 50)
                    }

                    if !selectedExerciseIDs.isEmpty {
                        NavigationLink(
                            destination: SelectedExercisesView(selectedExercises: selectedExercises),
                            label: {
                                Text("Confirm Selection (\(selectedExerciseIDs.count))")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(12)
                                    .padding()
                            }
                        )
                    }
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(workoutType)
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(isDarkMode ? Color.white : Color.black)
                }
                
            }
            
         
            .onAppear {
                if !selectedExerciseIDs.isEmpty {
                    selectedExerciseIDs.removeAll()
                }
                fetchUserPreferences()
                fetchExercises()
            }
            
        }
    }

    private func fetchExercises() {
        let group = DispatchGroup()
        isLoading = true
        exercises.removeAll()

        for muscle in muscleGroups {
            group.enter()
            guard let url = URL(string: "https://api.api-ninjas.com/v1/exercises?muscle=\(muscle)") else { continue }
            var request = URLRequest(url: url)
            request.setValue("pGcb118P0Oo+ZQs8wlAdrQ==guXDjnLJFwTsjy5i", forHTTPHeaderField: "X-Api-Key")
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                defer { group.leave() }
                if let data = data {
                    if let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
                        DispatchQueue.main.async {
                            
                            self.exercises.append(contentsOf: decoded)
                        }
                    }
                }
            }.resume()
        }

        group.notify(queue: .main) {
            isLoading = false
        }
    }

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
        print("Dark mode preference loaded: \(isDarkMode ? "Enabled" : "Disabled")")
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { return }

            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserDarkModePreference()
                }
            } catch {
                print("Failed to decode user profile.")
            }
        }.resume()
    }
}

struct ExerciseSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseView(workoutType: "Leg Workout")
    }
}
