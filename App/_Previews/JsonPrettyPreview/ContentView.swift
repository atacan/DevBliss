import ComposableArchitecture
import JsonPrettyFeature
import SwiftUI

struct ContentView: View {
    var body: some View {
        #if os(iOS)
            NavigationView {
                JsonPrettyView(store: Store(initialState: .init()) { JsonPrettyReducer() })
                    .padding()
            }
        #else
            JsonPrettyView(
                store: Store(
                    initialState: .init()
                ) {
                    JsonPrettyReducer()._printChanges()
                }
            )
            .padding()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
