import SwiftUI

struct ContentView: View {
    @State private var showHomepage = false
    @State private var showFirstCaloriePage = false
    @State private var isFromSettings: Bool = false

    var body: some View {
        NavigationStack {
            LoginSignupView(showHomepage: $showHomepage, showFirstCaloriePage: $showFirstCaloriePage)
                .fullScreenCover(isPresented: $showFirstCaloriePage) {
                    FirstLoginCaloriePageView(showHomepage: $showHomepage, isFromSettings: isFromSettings)
                }
                .navigationDestination(isPresented: $showHomepage) {
                    HomepageView(showHomepage: $showHomepage)
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
