import SwiftUI

struct ContentView: View {
    @State private var showHomepage = false
    @State private var showFirstCaloriePage = false

    var body: some View {
        NavigationStack {
            LoginSignupView(showHomepage: $showHomepage, showFirstCaloriePage: $showFirstCaloriePage)
                .navigationDestination(isPresented: $showHomepage) {
                    if showFirstCaloriePage {
                        FirstLoginCaloriePageView(showHomepage: $showHomepage)
                    } else {
                        HomepageView(showHomepage: $showHomepage)
                            .edgesIgnoringSafeArea(.all)
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
