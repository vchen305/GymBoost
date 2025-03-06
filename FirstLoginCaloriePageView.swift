import SwiftUI

struct FirstLoginCaloriePageView: View {
    @State private var selectedCalories: Int? = nil
    @State private var otherCalories: String = ""
    @State private var errorMessage: String? = nil
    @State private var navigateToHome: Bool = false
    
    let calorieOptions = [1000, 2000, 3000, 4000, 5000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Choose your preferred daily calorie needs")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(calorieOptions, id: \.self) { calorie in
                        HStack {
                            Checkbox(isChecked: self.selectedCalories == calorie) {
                                self.selectedCalories = calorie
                            }
                            Text("\(calorie) kcal")
                        }
                    }

                    HStack {
                        Checkbox(isChecked: selectedCalories == -1) {
                            selectedCalories = selectedCalories == -1 ? nil : -1
                        }
                        Text("Other")
                    }
                }
                .padding()

                if selectedCalories == -1 {
                    TextField("Enter your calories", text: $otherCalories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 10)
                }

                VStack {
                    Text("Selected Calorie Options:")
                        .font(.headline)

                    if let selectedCalories = selectedCalories {
                        if selectedCalories != -1 {
                            Text("\(selectedCalories) kcal")
                        } else if !otherCalories.isEmpty {
                            Text("Other: \(otherCalories) kcal")
                        }
                    }
                }
                .padding()

                Button(action: {
                    if selectedCalories == nil {
                        errorMessage = "Please select a calorie option"
                    } else {
                        errorMessage = nil
                        if selectedCalories == -1 && otherCalories.isEmpty {
                            errorMessage = "Please enter a valid calorie number."
                        } else {
                            navigateToHome = true
                        }
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
            .navigationDestination(isPresented: $navigateToHome) {
                HomepageView()
            }
        }
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

struct FirstLoginCaloriePage_Previews: PreviewProvider {
    static var previews: some View {
        FirstLoginCaloriePageView()
    }
}
