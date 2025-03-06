import SwiftUI

struct ContentView: View {
    @State private var showHomepage = false
    @State private var showFirstCaloriePage = false
    var body: some View {
        NavigationView {
            VStack {
                if showHomepage {
                    if showFirstCaloriePage {
                        FirstLoginCaloriePageView()
                    } else {
                        HomepageView()
                    }
                } else {
                    LoginSignupView(showHomepage: $showHomepage, showFirstCaloriePage: $showFirstCaloriePage)
                }
            }
            .padding()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
