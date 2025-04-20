import SwiftUI

struct SmallCard: View {
    let title: String
    let goal: String
    let value: String
    let icon: String
    let color: Color
    @Binding var isDarkMode: Bool // Binding to dark mode state

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(isDarkMode ? .white : .black)

            Text("Daily Goal \(goal)")
                .font(.caption)
                .foregroundColor(isDarkMode ? .white : .gray)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(isDarkMode ? .white : .black) 
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isDarkMode ? Color.black.opacity(0.2) : Color.white))
        .shadow(radius: isDarkMode ? 0 : 3)
     
    }
}
