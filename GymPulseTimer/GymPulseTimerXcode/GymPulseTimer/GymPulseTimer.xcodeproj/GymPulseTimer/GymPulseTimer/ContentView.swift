import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            SetupView()
                .navigationTitle("Gym Pulse Timer")
                .navigationBarTitleDisplayMode(.large)
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
