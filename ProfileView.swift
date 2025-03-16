import SwiftUI

struct ProfileView: View {
    @State private var isDarkMode: Bool = false
    @AppStorage("authToken") private var authToken: String = ""
    @Binding var showHomepage: Bool
    @State private var isLoggedOut = false
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var username: String = "Loading..."
    @State private var email: String = "Loading..."
    @State private var avatarURL: String = ""
    @State private var showSettings = false
    
    var body: some View {
        VStack {
            VStack {
                if let url = URL(string: avatarURL), !avatarURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                }
                
                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Edit Profile Avatar")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .padding(.top, 10)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Username: \(username)")
                    .font(.title)
                    .padding(.bottom, 5)
                Text("Email: \(email)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    showSettings = true
                }) {
                    Text("Settings")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                        .font(.title2)
                }
                .fullScreenCover(isPresented: $showSettings) {
                    SettingsView(isDarkMode: $isDarkMode, showHomepage: $showHomepage, username: username)
                }
                
                Button(action: {
                    logout()
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .font(.title2)
                }
                .padding(.top, 10)
            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitle("Profile", displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .foregroundColor(isDarkMode ? .white : .black)
                    .font(.title2)
            }
        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
        .foregroundColor(isDarkMode ? Color.white : Color.black)
        .onAppear {
            fetchUserProfile()
        }
        .alert(isPresented: $isLoggedOut) {
            Alert(
                title: Text("Logged Out"),
                message: Text("You have been logged out successfully."),
                dismissButton: .default(Text("OK")) {
                    showHomepage = false
                }
            )
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            uploadImage()
        }) {
            ImagePickerView(image: $selectedImage)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(isDarkMode: $isDarkMode, showHomepage: $showHomepage, username: username)
        }
    }
    
    private func fetchUserProfile() {
        guard let url = URL(string: "http://localhost:3000/profile") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(UserProfile.self, from: data)
                
                DispatchQueue.main.async {
                    self.username = decodedResponse.username
                    loadUserPreferences()
                    
                    if let avatarUrl = decodedResponse.avatar_url, !avatarUrl.isEmpty {
                        self.avatarURL = avatarUrl
                        UserDefaults.standard.set(avatarUrl, forKey: "avatarURL")
                        UserDefaults.standard.synchronize()
                    } else {
                        self.avatarURL = ""
                        UserDefaults.standard.removeObject(forKey: "avatarURL")
                    }
                }
            } catch {
            }
        }.resume()
    }
    
    private func loadUserPreferences() {
        let userKey = "isDarkMode_\(username)"
        isDarkMode = UserDefaults.standard.bool(forKey: userKey)
    }
    
    private func uploadImage() {
        guard let selectedImage = selectedImage else {
            return
        }
        
        guard let url = URL(string: "http://localhost:3000/upload-avatar") else {
            return
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        
        var body = Data()
        let filename = "avatar.jpg"
        let fieldName = "avatar"
        let mimeType = "image/jpeg"
        
        if let imageData = selectedImage.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        } else {
            return
        }
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            if httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.fetchUserProfile()
                }
            }
        }.resume()
    }
    
    private func logout() {
        authToken = ""
        isLoggedOut = true
        self.avatarURL = ""
        UserDefaults.standard.removeObject(forKey: "avatarURL")
    }
}


struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Environment(\.dismiss) var dismiss
    @State private var showCalorieAdjustment = false
    @Binding var showHomepage: Bool
    var username: String

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.top, 60)
                }
                .padding()

                Spacer()

                Text("Settings")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 60)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "chevron.left")
                        .opacity(0)
                }
                .padding()
            }

            Toggle("Dark Mode", isOn: $isDarkMode)
                          .padding()
                          .onChange(of: isDarkMode) {
                              let userKey = "isDarkMode_\(username)"
                              UserDefaults.standard.set(isDarkMode, forKey: userKey)
                          }

            Button(action: {
                showCalorieAdjustment = true
            }) {
                Text("Adjust Daily Calories")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .background(isDarkMode ? Color.black.opacity(0.8) : Color.white)
        .foregroundColor(isDarkMode ? Color.white : Color.black)
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showCalorieAdjustment) {
            FirstLoginCaloriePageView(showHomepage: $showHomepage, isFromSettings: true)
        }
    }
}

/// User Profile Model
struct UserProfile: Codable {
    let username: String
    let avatar_url: String?
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView(showHomepage: .constant(true))
        }
    }
}
