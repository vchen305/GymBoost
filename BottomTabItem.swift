import SwiftUI

struct BottomTabItem: View {
    let icon: String
    let label: String
    var highlighted: Bool = false
    var isDarkMode: Bool

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(highlighted ? .orange : (isDarkMode ? .orange : .black))
            
            Text(label)
                .font(.caption)
                .foregroundColor(highlighted ? .orange : (isDarkMode ? .orange : .black))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
