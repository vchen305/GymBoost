import SwiftUI

struct AIChatView: View {
    @Binding var isDarkMode: Bool
    @AppStorage("authToken") private var authToken: String = ""
    @State private var aiResponse: String = ""
    @State private var isLoading: Bool = false
    @State private var showAnswer: Bool = false

    // AI Chat questions
    let questions: [String] = [
        "If I swap a carb‑heavy snack for something higher in protein (e.g. Greek yogurt vs. granola), what could I choose?",
        "Given my protein‑to‑calorie ratio today, should I use more of my remaining calories for protein? Suggest foods like chicken, turkey, or Greek yogurt.",
        "How many grams of protein per 100 calories am I at, and which lean proteins (e.g. fish, tofu, egg whites) can boost it?",
        "What’s my calorie balance relative to my goal, and should I eat more to stay on track?",
        "Based on my carb‑to‑fat ratio, am I skewed toward carbs or fats? Recommend a swap (e.g. nuts for chips) to balance."
    ]

    var body: some View {
        NavigationStack {
            content
        }
        .environment(\.colorScheme, isDarkMode ? .dark : .light)
    }

    private var content: some View {
        ZStack(alignment: .bottom) {
            (isDarkMode ? Color.black.opacity(0.8) : Color(UIColor.systemGray6))
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Ask AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .black)
                    .padding(.top)

                if !showAnswer {
                    questionList
                } else {
                    answerView
                }

                Spacer(minLength: 70)
            }

            if isLoading {
                loadingOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    private var questionList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(questions, id: \.self) { question in
                    Button(action: {
                        aiResponse = ""
                        withAnimation { showAnswer = true }
                        sendQuestionToAPI(question: question)
                    }) {
                        Text(question)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isDarkMode ? Color.blue.opacity(0.7) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding([.leading, .trailing])
        }
    }

    private var answerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    withAnimation {
                        showAnswer = false
                        aiResponse = ""
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.title3)
                    .foregroundColor(isDarkMode ? .white : .blue)
                    .padding(.leading)
                }
                Spacer()
            }
            .padding(.top, 12)

            ScrollView {
                if isLoading {
                    Text("Loading answer...")
                        .italic()
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(aiResponse)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(isDarkMode ? .white : .black)
                }
            }
            .scrollIndicators(.visible)
            .frame(maxWidth: .infinity)
            .background(isDarkMode ? Color.black.opacity(0.7) : Color.white)
            .cornerRadius(12)
            .padding([.leading, .trailing])
        }
    }

    private var loadingOverlay: some View {
        ProgressView()
            .scaleEffect(1.5)
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 10)
            .zIndex(2)
    }

    func sendQuestionToAPI(question: String) {
        guard !authToken.isEmpty else {
            aiResponse = "Error: No auth token. Please log in."
            return
        }
        isLoading = true

        guard let url = URL(string: "http://localhost:3000/ask-ai") else {
            aiResponse = "Error: Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Authorization")

        let body: [String: String] = ["question": question]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            aiResponse = "Error: Unable to serialize request body"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async { isLoading = false }
            if let error = error {
                DispatchQueue.main.async { aiResponse = "Network error: \(error.localizedDescription)" }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { aiResponse = "Error: No data received" }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(AIResponse.self, from: data)
                DispatchQueue.main.async { aiResponse = decoded.answer }
            } catch {
                DispatchQueue.main.async { aiResponse = "Error decoding response: \(error.localizedDescription)" }
            }
        }.resume()
    }
}

struct AIResponse: Codable {
    let answer: String
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView(isDarkMode: .constant(true))
    }
}
