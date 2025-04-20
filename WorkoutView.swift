import SwiftUI

struct WorkoutView: View {
    @State private var isDarkMode: Bool = false
    @State private var username: String = "Loading..."
    @AppStorage("authToken") private var authToken: String = ""
    
    let workouts = [
        "Leg Workout", "Chest Workout", "Arms Workout", "Back Workout", "Shoulder Workout"
    ]
    
    let gradients: [LinearGradient] = [
        LinearGradient(gradient: Gradient(colors: [.red, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(gradient: Gradient(colors: [.green, .yellow]), startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(gradient: Gradient(colors: [.pink, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(gradient: Gradient(colors: [.indigo, .teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Workouts")
                        .font(.system(size: 40, weight: .bold))
                        .bold()
                        .foregroundColor(isDarkMode ? Color.white : Color.black)
                    
                    Spacer(minLength: 20)
                    
                    ForEach(0..<workouts.count, id: \.self) { index in
                        NavigationLink(destination: ExerciseView(workoutType: workouts[index])) {
                            WorkoutCard(title: workouts[index], gradient: gradients[index], isDarkMode: isDarkMode)
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                fetchUserPreferences()
            }
            .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserDarkModePreference()
                }
            } catch { }
        }.resume()
    }
}


struct WorkoutCard: View {
    let title: String
    let gradient: LinearGradient
    let isDarkMode: Bool
    
    var body: some View {
        ZStack {
            gradient
                .cornerRadius(12)
                .frame(height: 100)
                .shadow(radius: 4)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.white)
                .padding()
        }
        .padding(.horizontal)
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutView()
    }
}
