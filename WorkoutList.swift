import SwiftUI

struct Workout: Identifiable, Codable {
    let id = UUID()
    let day: String
    let sets: Int
    let reps: Int
    let exerciseName: String

    enum CodingKeys: String, CodingKey {
        case day, sets, reps
        case exerciseName = "exercise_name"
    }
}

struct WorkoutList: View {
    @State private var workoutsByDay: [String: [Workout]] = [:]
    @State private var username: String = "Loading..."
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black.opacity(0.8) : Color.white)
                .ignoresSafeArea()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(workoutsByDay.keys.sorted(by: sortDays), id: \.self) { day in
                        Text(day)
                            .font(.title2)
                            .bold()
                            .foregroundColor(isDarkMode ? .white : .black)
                            .padding(.horizontal)
                            .padding(.top, day == workoutsByDay.keys.sorted(by: sortDays).first ? 20 : 0)

                        ForEach(workoutsByDay[day] ?? []) { workout in
                            WorkoutCardList(workout: workout, isDarkMode: isDarkMode)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Workout List")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(isDarkMode ? Color.orange : Color.black)
            }
        }
        .onAppear {
            fetchUserPreferences()
            fetchWorkouts()
        }
    }

    func fetchWorkouts() {
        guard let url = URL(string: "http://localhost:3000/get-workouts") else { return }

        guard let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            print("Auth token not found.")
            return
        }

        var request = URLRequest(url: url)
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }

            if let decoded = try? JSONDecoder().decode([Workout].self, from: data) {
                DispatchQueue.main.async {
                    workoutsByDay = Dictionary(grouping: decoded, by: { $0.day })
                }
            }
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

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
        print("Dark mode preference loaded: \(isDarkMode ? "Enabled" : "Disabled")")
    }

    func sortDays(_ a: String, _ b: String) -> Bool {
        let order = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return order.firstIndex(of: a)! < order.firstIndex(of: b)!
    }
}

// MARK: - Workout Card (Dark mode aware)
struct WorkoutCardList: View {
    let workout: Workout
    let isDarkMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.exerciseName)
                .font(.headline)
                .foregroundColor(isDarkMode ? .white : .primary)

            HStack {
                Text("Sets: \(workout.sets)")
                Text("Reps: \(workout.reps)")
            }
            .font(.subheadline)
            .foregroundColor(isDarkMode ? .gray : .secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isDarkMode ? Color.black.opacity(0.3) : Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: isDarkMode ? .clear : .gray.opacity(0.15), radius: 3)
    }
}

// MARK: - Preview
struct WorkoutList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutList()
        }
    }
}
