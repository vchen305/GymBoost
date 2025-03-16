import SwiftUI

struct SmallCard: View {
    let title: String
    let goal: String
    let value: String
    let icon: String
    let color: Color
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text("Daily Goal \(goal)")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.2)) 
        )
        .shadow(radius: isDarkMode ? 0 : 3)
    }
}
