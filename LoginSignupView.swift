//
//  LoginSignupView.swift
//  GymBoost
//
//  Created by Vincent Chen on 3/6/25.
//

import SwiftUI



struct LoginSignupView: View{
    
    @State private var isSignUpView = false
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isErrorVisible = false
    @State private var isSignUpSuccess = false
    @Binding var showHomepage: Bool
    @Binding var showFirstCaloriePage: Bool
    
    var body: some View{
        Text(isSignUpView ? "Sign Up" : "Login")
            .font(.largeTitle)
            .padding()
        
        TextField("Username", text: $username)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
        
        SecureField("Password", text: $password)
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
        
        Button(action: {
            if isSignUpView {
                signUpUser()
                username = ""
                password = ""
            } else {
                isSignUpSuccess = false
                loginUser()
            }
        }) {
            Text(isSignUpView ? "Sign Up" : "Login")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.top)
        }
        
        Button(action: {
            isSignUpView.toggle()
            errorMessage = ""
            isErrorVisible = false
            isSignUpSuccess = false
        }) {
            Text(isSignUpView ? "Already have an account? Login" : "Don't have an account? Sign Up")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.top, 10)
        
        
        if isSignUpSuccess && !isSignUpView {
            Text("Sign Up Successful! Please log in.")
                .foregroundColor(.green)
                .padding(.top, 20)
                .transition(.opacity)
        }
        
        
        if !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding(.top, 20)
        }
        
        
        
    }
    func signUpUser() {
        let parameters: [String: Any] = [
            "username": username.isEmpty ? "" : username,
            "password": password.isEmpty ? "" : password
        ]
        
        guard let url = URL(string: "http://localhost:3000/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error: Cannot convert parameters to JSON")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    if let responseDict = jsonResponse as? [String: Any], let message = responseDict["message"] as? String {
                        DispatchQueue.main.async {
                            errorMessage = ""
                            isErrorVisible = false
                            
                            if message == "User registered successfully" {
                                isSignUpSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isSignUpView = false  // Switch to login view
                                }
                            } else {
                                errorMessage = message
                                isErrorVisible = true
                            }
                        }
                    }
                } catch {
                    print("Error: Cannot parse JSON response")
                }
            }
        }
        
        task.resume()
    }
    
    func loginUser() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in both username and password."
            isErrorVisible = true
            return
        }
        
        let parameters: [String: Any] = [
            "username": username,
            "password": password,
        ]
        
        guard let url = URL(string: "http://localhost:3000/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error: Cannot convert parameters to JSON")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                    if let responseDict = jsonResponse as? [String: Any], let message = responseDict["message"] as? String {
                        DispatchQueue.main.async {
                            if message == "Login successful" {
                                errorMessage = ""
                                isErrorVisible = false
                                showHomepage = true  // Show the homepage
                                
                                // Check if it's the user's first login
                                if let firstLogin = responseDict["firstLogin"] as? Int, firstLogin == 1 {
                                    showFirstCaloriePage = true  // Show the first calorie page
                                }
                            } else {
                                errorMessage = message
                                isErrorVisible = true
                            }
                        }
                    }
                } catch {
                    print("Error: Cannot parse JSON response")
                }
            }
        }
        
        task.resume()
        
    }
}
