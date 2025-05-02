import SwiftUI

struct WorkoutOptionsView: View {
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = "Loading..."
    @State private var showHomepage: Bool = false

    var body: some View {
        ZStack {
            (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Choose an Option")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .black)
                    .padding(.top, 40)

                NavigationLink(destination: WorkoutView()) {
                    Text("Select Workouts")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                NavigationLink(destination: WorkoutList()) {
                    Text("View Saved Workouts")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUserPreferences()
        }
    }

    private func fetchUserPreferences() {
        guard let url = URL(string: "http://localhost:3000/profile") else {
            return
        }

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
            } catch {
                print("Failed to decode user profile")
            }
        }.resume()
    }

    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
    }
}

struct WorkoutOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutOptionsView()
        }
    }
}
