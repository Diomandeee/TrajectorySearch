import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Trajectory Search")
                    .font(.largeTitle.bold())

                Text("Welcome to Trajectory Search")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Trajectory Search")
        }
    }
}

#Preview {
    ContentView()
}
