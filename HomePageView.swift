import SwiftUI

struct HomepageView: View {
    @Binding var showHomepage: Bool
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""
    @State private var username: String = "Loading..."

    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: ProfileView(showHomepage: $showHomepage)) {
                    Image(systemName: "person.circle")
                        .font(.title)
                        .foregroundColor(isDarkMode ? .white : .black)
                        .padding()
                        .padding(.top, 30)
                }
               
                Text("GymBoost")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.orange)
                    .padding(.top, 60)
                    .padding(.leading, 45)

                Spacer()
            }
            .padding(.horizontal)
            
            VStack {
                Text("Calories")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.orange, lineWidth: 10)
                        .rotationEffect(.degrees(-90))
                    Text("650\nNeeded")
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
                .frame(width: 100, height: 100)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Daily Goal").font(.caption)
                        Text("2750").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Consumed").font(.caption)
                        Text("2100").bold()
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Burned").font(.caption)
                        Text("300").bold()
                            .foregroundColor(.red)
                    }
                }
                .foregroundColor(isDarkMode ? .white : .black)
                .padding()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
            .shadow(radius: 3)
            
            HStack(spacing: 10) {
                SmallCard(title: "Water", goal: "115oz", value: "56oz", icon: "drop.fill", color: .blue)
                SmallCard(title: "Steps", goal: "10000", value: "2100", icon: "figure.walk", color: .green)
            }
            
            VStack {
                Text("Weight")
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .black)
                Spacer()
                Text("Graph Placeholder")
                    .foregroundColor(isDarkMode ? .white : .black)
                Spacer()
            }
            .frame(height: 120)
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(isDarkMode ? Color.gray.opacity(0.3) : Color.white))
            .shadow(radius: 3)
            .padding(.horizontal)
            
            Spacer()
            
            HStack {
                BottomTabItem(icon: "house", label: "Home", isDarkMode: isDarkMode)
                BottomTabItem(icon: "dumbbell", label: "Workouts", isDarkMode: isDarkMode)
                BottomTabItem(icon: "leaf", label: "Nutrition", highlighted: true, isDarkMode: isDarkMode)
                BottomTabItem(icon: "line.3.horizontal", label: "More", isDarkMode: isDarkMode)
            }
            .frame(height: 60)
            .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
            .shadow(radius: isDarkMode ? 0 : 2)

        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
        .navigationBarBackButtonHidden(true)
        .edgesIgnoringSafeArea(.all)
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
            if let error = error {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserDarkModePreference()
                }
            } catch {
            }
        }.resume()
    }
    
    private func loadUserDarkModePreference() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomepageView(showHomepage: .constant(true))
    }
}
